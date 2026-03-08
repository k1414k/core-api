class Auction::V1::OffersController < ApplicationController
  before_action :authenticate_user!

  def create
    item = Item.find(params[:item_id])
    amount = params[:amount].to_i

    return render json: { error: "オファー額を入力してください" }, status: :unprocessable_entity if amount <= 0
    return render json: { error: "自分の商品にはオファーできません" }, status: :forbidden if item.user_id == current_user.id
    return render json: { error: "この商品は値段交渉に対応していません" }, status: :unprocessable_entity unless item.negotiation?
    return render json: { error: "この商品は購入できません" }, status: :unprocessable_entity unless item.listed?

    offer = item.offers.build(user: current_user, amount: amount)
    if offer.save
      render json: { id: offer.id, amount: offer.amount, status: offer.status }, status: :created
    else
      render json: { errors: offer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    offer = Offer.find(params[:id])
    return head :forbidden unless offer.item.user_id == current_user.id

    case params[:status]
    when "accepted"
      offer.update!(status: :accepted)
      render json: { id: offer.id, status: offer.status }
    when "rejected"
      offer.update!(status: :rejected)
      render json: { id: offer.id, status: offer.status }
    else
      render json: { error: "無効なステータスです" }, status: :unprocessable_entity
    end
  end
end
