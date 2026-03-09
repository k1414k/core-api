class Auction::V1::CategoriesController < ApplicationController
  def index
    categories = Category.all
    render json: categories.map { |category| category_json(category) }
  end

  private

  def category_json(category)
    category.as_json.merge(
      image_url: category.image.attached? ? rails_blob_path(category.image, only_path: true) : nil
    )
  end

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.permit(:name)
  end
end
