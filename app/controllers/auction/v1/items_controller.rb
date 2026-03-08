class Auction::V1::ItemsController < ApplicationController
  before_action :set_item, only: [:show, :update, :destroy]
  before_action :authenticate_user!, only: [:create] # index/show は未ログインでも閲覧可

  def ending_soon
    items = Item.includes(:user, images_attachments: :blob)
      .where(sale_type: Item.sale_types[:auction])
      .where("end_at IS NOT NULL AND end_at > ?", Time.current)
      .order(end_at: :asc)
      .limit(10)
    render json: items.map { |item| item_list_json(item) }
  end

  def one_yen
    items = Item.includes(:user, images_attachments: :blob)
      .where(sale_type: Item.sale_types[:auction], start_price: 1)
      .where("end_at IS NOT NULL AND end_at > ?", Time.current)
      .order(created_at: :desc)
      .limit(10)
    render json: items.map { |item| item_list_json(item) }
  end

  def recently_sold
    orders = Order.where(status: :completed)
      .includes(item: [:user, images_attachments: :blob])
      .order(updated_at: :desc)
      .limit(10)
    render json: orders.map { |order|
      item = order.item
      {
        **item_list_json(item),
        sold_price: item.price,
        updated_at: order.updated_at.iso8601
      }
    }
  end

  def user_items
    user = User.find(params[:id])
    items = user.items.where(trading_status: [Item.trading_statuses[:listed], Item.trading_statuses[:trading], Item.trading_statuses[:sold]])
      .includes(:category, images_attachments: :blob).order(created_at: :desc)
    render json: {
      user: { id: user.id, nickname: user.nickname, avatar_url: user.avatar.attached? ? rails_blob_path(user.avatar, only_path: true) : nil },
      items: items.map { |item|
        {
          id: item.id,
          title: item.title,
          price: item.price,
          trading_status: item.trading_status,
          image: item.images.attached? ? blob_path_for(item.images.first) : nil,
          created_at: item.created_at
        }
      }
    }
  end

  def index
    items = Item.includes(:user, images_attachments: :blob)

    render json: items.map { |item| item_list_json(item) }
  end

  def show
    item = Item.includes(:user, images_attachments: :blob).find(params[:id])

    render json: {
      **item.as_json,
      user_nickname: item.user.nickname,
      created_by_current_user: current_user&.id == item.user_id,
      is_favorited: current_user&.favorited?(item) || false,
      images: item.images.map { |img| blob_path_for(img) },
      sale_type: item.sale_type,
      start_price: item.start_price,
      end_at: item.end_at,
      min_increment: item.min_increment || 100,
      current_bid: item.bids.maximum(:amount),
      bids_count: item.bids.count
    }
  end

  def create
    p = item_params
    p[:condition] = p[:condition].to_i if p[:condition].present?
    p[:trading_status] = p[:trading_status].present? ? p[:trading_status].to_i : Item.trading_statuses[:listed]
    p[:sale_type] = p[:sale_type].present? ? p[:sale_type].to_i : Item.sale_types[:fixed_price]
    p[:start_price] = p[:start_price].to_i if p[:start_price].present?
    p[:min_increment] = p[:min_increment].to_i if p[:min_increment].present?

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
      :sale_type,
      :start_price,
      :end_at,
      :min_increment,
      images: []
    )
  end

  def blob_path_for(blob)
    rails_blob_path(blob, only_path: true)
  end

  def item_list_json(item)
    {
      **item.as_json,
      is_favorited: current_user ? current_user.favorited?(item) : false,
      image: item.images.attached? ? blob_path_for(item.images.first) : nil,
      user_nickname: item.user.nickname,
      sale_type: item.sale_type,
      start_price: item.start_price,
      end_at: item.end_at,
      current_bid: item.bids.maximum(:amount),
      bids_count: item.bids.count
    }
  end
end