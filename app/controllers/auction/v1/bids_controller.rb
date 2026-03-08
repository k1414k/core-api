class Auction::V1::BidsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def index
    bids = @item.bids.includes(:user).order(created_at: :desc)
    render json: bids.map { |b|
      { id: b.id, amount: b.amount, user_nickname: b.user.nickname, created_at: b.created_at }
    }
  end

  def create
    amount = params[:amount].to_i
    return render json: { error: "入札額を入力してください" }, status: :unprocessable_entity if amount <= 0
    return render json: { error: "自分の商品には入札できません" }, status: :forbidden if @item.user_id == current_user.id
    return render json: { error: "この商品はオークションではありません" }, status: :unprocessable_entity unless @item.auction?
    return render json: { error: "オークションは終了しています" }, status: :unprocessable_entity if @item.end_at.present? && @item.end_at < Time.current

    min_increment = @item.min_increment || 100
    current_max = @item.bids.maximum(:amount)
    min_bid = (current_max || @item.start_price || @item.price) + min_increment

    return render json: { error: "最低入札額は¥#{min_bid}以上です" }, status: :unprocessable_entity if amount < min_bid

    bid = @item.bids.build(user: current_user, amount: amount)
    if bid.save
      render json: { id: bid.id, amount: bid.amount }, status: :created
    else
      render json: { errors: bid.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end
end
