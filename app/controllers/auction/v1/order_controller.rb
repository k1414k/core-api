class Auction::V1::OrderController < ApplicationController
  before_action :authenticate_user!

  def create
    item = Item.find(order_params[:item_id])

    # 購入可否チェック
    validate_purchase!(item)

    order = nil
    ActiveRecord::Base.transaction do
      # 1. オーダーを作成（配送先をスナップショットとして保存）
      shipping_address = build_shipping_address
      order = Order.create!(
        item: item,
        buyer_id: current_user.id,
        seller_id: item.user_id,
        shipping_address: shipping_address,
        status: order_status_for_payment(order_params[:payment_method])
      )

      # 2. 支払い処理（ポイントの場合は即時引き落とし）
      process_payment!(item, order_params[:payment_method])

      # 3. ポイント決済の場合は売り手の売上（balance）に加算
      if order_params[:payment_method].to_s == "ポイント"
        seller = item.user
        seller.update!(balance: seller.balance + item.price)
      end

      # 4. 商品を「取引中」にする
      item.update!(trading_status: :trading)
    end

    render json: { message: "success", order_id: order.id }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "商品が見つかりません" }, status: :not_found
  rescue OrderController::PurchaseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  class PurchaseError < StandardError; end

  def order_params
    params.permit(:item_id, :last_address_name, :last_address_detail, :payment_method, :address_id)
  end

  def validate_purchase!(item)
    raise PurchaseError, "自分の商品は購入できません" if item.user_id == current_user.id
    raise PurchaseError, "この商品は購入できません" unless item.listed?
  end

  def build_shipping_address
    if order_params[:address_id].present?
      address = current_user.addresses.find(order_params[:address_id])
      "#{address.name} #{address.address}"
    else
      name = order_params[:last_address_name].to_s.strip
      detail = order_params[:last_address_detail].to_s.strip
      raise PurchaseError, "配送先を入力してください" if name.blank? || detail.blank?
      "#{name} #{detail}"
    end
  end

  def order_status_for_payment(payment_method)
    # ポイント決済の場合は即時入金扱いで shipping 待ちへ
    payment_method == "ポイント" ? :waiting_shipping : :waiting_payment
  end

  def process_payment!(item, payment_method)
    return unless payment_method == "ポイント"

    raise PurchaseError, "残高が足りません" if current_user.points < item.price

    current_user.update!(points: current_user.points - item.price)
  end
end