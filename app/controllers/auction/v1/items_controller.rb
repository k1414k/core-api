class Auction::V1::ItemsController < ApplicationController
  include Rails.application.routes.url_helpers

  before_action :set_item, only: [:show, :update, :destroy]
  before_action :authenticate_user!, only: [:create]

  def index
    items = Item.includes(images_attachments: :blob)

    render json: items.map { |item|
      {
        **item.as_json,
        is_favorited: current_user ? current_user.favorited?(item) : false,
        image: item.images.attached? ? public_blob_url(item.images.first) : nil
      }
    }
  end

  def show
    item = Item.includes(images_attachments: :blob).find(params[:id])

    render json: {
      **item.as_json,
      user_nickname: item.user.nickname,
      created_by_current_user: current_user&.id == item.user_id,
      is_favorited: current_user&.favorited?(item) || false,
      images: item.images.map { |img| public_blob_url(img) }
    }
  end

  def create
    p = item_params
    p[:condition] = p[:condition].to_i if p[:condition].present?
    p[:trading_status] = p[:trading_status].present? ? p[:trading_status].to_i : Item.trading_statuses[:listed]

    @item = current_user.items.build(p)

    if @item.save
      render json: @item, status: :created
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      render json: @item
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    head :no_content
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(
      :title,
      :description,
      :price,
      :category_id,
      :favorites,
      :condition,
      :trading_status,
      images: []
    )
  end

  def public_blob_url(blob_or_attachment)
    rails_blob_url(blob_or_attachment, host: public_api_host)
  end

  def public_api_host
    ENV["PUBLIC_API_BASE_URL"] || "http://localhost:3000"
  end
end