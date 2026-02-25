class Auction::V1::FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def toggle
    favorite = current_user.favorites.find_by(item: @item)

    if favorite
      favorite.destroy
      render json: { favorited: false }
    else
      current_user.favorites.create!(item: @item)
      render json: { favorited: true }
    end
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end
end
