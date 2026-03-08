class Auction::V1::MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order

  def index
    messages = @order.messages.includes(:user).order(created_at: :asc)
    render json: messages.map { |m| message_json(m) }
  end

  def create
    message = @order.messages.build(user: current_user, content: params[:content].to_s.strip)
    if message.save
      render json: message_json(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
    head :forbidden unless @order.buyer_id == current_user.id || @order.seller_id == current_user.id
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      user_id: message.user_id,
      user_nickname: message.user.nickname,
      created_at: message.created_at
    }
  end
end
