class Auction::V1::UsersController < ApplicationController
  before_action :authenticate_user!

  def my_profile
    render json: {
      name: current_user.name,
      nickname: current_user.nickname,
      email: current_user.email,
      balance: current_user.balance,
      points: current_user.points,
      introduction: current_user.introduction,
      role: current_user.role,
      avatar_url: current_user.avatar.attached? ? rails_blob_path(current_user.avatar, only_path: true) : nil
    }
  end


  MAX_BALANCE_TRANSACTION = 100_000
  MAX_POINTS_TRANSACTION  = 1_000_000
  ALLOWED_TYPES = %w[balance points charge].freeze

  def update_wallet
    amount = params.require(:amount).to_i
    type   = params.require(:type).to_s

    return error("invalid type") unless ALLOWED_TYPES.include?(type)

    if type == "charge"
      # 売上（balance）をポイントに振り替え
      return error("チャージする金額を入力してください") if amount <= 0
      current_user.with_lock do
        return error("売上高が足りません") if current_user.balance < amount
        current_user.update!(
          balance: current_user.balance - amount,
          points: current_user.points + amount
        )
      end
    else
      return error("amount must not be 0") if amount.zero?
      limit = type == "balance" ? MAX_BALANCE_TRANSACTION : MAX_POINTS_TRANSACTION
      return error("amount is too large") if amount.abs > limit
      current_user.with_lock do
        current_value = current_user.public_send(type)
        new_value = current_value + amount
        return error("insufficient #{type}") if new_value < 0
        current_user.update!(type => new_value)
      end
    end

    render json: {
      balance: current_user.balance,
      points: current_user.points
    }
  end

  def update_avatar
    if params[:avatar].blank?
      return error("avatar is required")
    end

    current_user.avatar.attach(params[:avatar])

    render json: {
      avatar_url: url_for(current_user.avatar)
    }
  end

  def error(message)
    render json: { error: message }, status: :unprocessable_entity
  end


end
