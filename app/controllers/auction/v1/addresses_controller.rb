class Auction::V1::AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_address, only: [:update, :destroy]

  def index
    addresses = current_user.addresses.order(created_at: :asc)
    render json: addresses
  end

  def create
    address = current_user.addresses.build(address_params)
    if address.save
      render json: address, status: :created
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @address.update(address_params)
      render json: @address
    else
      render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy!
    head :no_content
  end

  private

  def set_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.permit(:title, :name, :address, :postal_code, :phone_number)
  end
end
