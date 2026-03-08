class Auction::V1::OrderController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update]

  def index
    role = params[:role]

    orders =
      if role == "seller"
        current_user.sell_orders
      else
        current_user.buy_orders
      end

    orders = orders.includes(:item, :buyer, :seller).order(created_at: :desc)

    render json: orders.map { |o| order_json(o) }
  end

  def show
    render json: order_detail_json(@order)
  end

  def create
    item = Item.find(order_params[:item_id])

    validate_purchase!(item)

    order = nil
    ActiveRecord::Base.transaction do
      shipping_address = build_shipping_address

      order = Order.create!(
        item: item,
        buyer_id: current_user.id,
        seller_id: item.user_id,
        shipping_address: shipping_address,
        status: order_status_for_payment(order_params[:payment_method])
      )

      process_payment!(item, order_params[:payment_method])

      if order_params[:payment_method].to_s == "ポイント"
        seller = item.user
        seller.update!(balance: seller.balance + item.price)
      end

      item.update!(trading_status: :trading)
    end

    render json: { message: "success", order_id: order.id }, status: :ok

  rescue ActiveRecord::RecordNotFound
    render json: { error: "商品が見つかりません" }, status: :not_found
  rescue PurchaseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    case params[:status]
    when "waiting_shipping"
      return head :forbidden unless @order.seller_id == current_user.id
      @order.update!(status: :waiting_shipping)
    when "waiting_review"
      return head :forbidden unless @order.seller_id == current_user.id
      @order.update!(status: :waiting_review)
    when "completed"
      return head :forbidden unless @order.buyer_id == current_user.id
      @order.update!(status: :completed)
      @order.item.update!(trading_status: :sold) if @order.item.trading?
    else
      return render json: { error: "無効なステータスです" }, status: :unprocessable_entity
    end

    render json: order_detail_json(@order)
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
    payment_method == "ポイント" ? :waiting_shipping : :waiting_payment
  end

  def process_payment!(item, payment_method)
    return unless payment_method == "ポイント"

    raise PurchaseError, "残高が足りません" if current_user.points < item.price

    current_user.update!(points: current_user.points - item.price)
  end

  def set_order
    @order = Order.find(params[:id])
    head :forbidden unless @order.buyer_id == current_user.id || @order.seller_id == current_user.id
  end

  def order_json(order)
    {
      id: order.id,
      item_id: order.item_id,
      item_title: order.item.title,
      item_image: order.item.images.attached? ? rails_blob_path(order.item.images.first, only_path: true) : nil,
      price: order.item.price,
      status: order.status,
      buyer_nickname: order.buyer.nickname,
      seller_nickname: order.seller.nickname,
      created_at: order.created_at
    }
  end

  def order_detail_json(order)
    {
      id: order.id,
      item_id: order.item_id,
      item: {
        id: order.item.id,
        title: order.item.title,
        price: order.item.price,
        image: order.item.images.attached? ? rails_blob_path(order.item.images.first, only_path: true) : nil
      },
      buyer: { id: order.buyer.id, nickname: order.buyer.nickname },
      seller: { id: order.seller.id, nickname: order.seller.nickname },
      status: order.status,
      shipping_address: order.shipping_address,
      created_at: order.created_at
    }
  end
end