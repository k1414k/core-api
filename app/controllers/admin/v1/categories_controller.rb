class Admin::V1::CategoriesController < Admin::V1::BaseController
  before_action -> { authorize_admin_resource!(:categories, :read) }, only: [:index]
  before_action -> { authorize_admin_resource!(:categories, :create) }, only: [:create]
  before_action -> { authorize_admin_resource!(:categories, :update) }, only: [:update]
  before_action -> { authorize_admin_resource!(:categories, :destroy) }, only: [:destroy]
  before_action :set_category, only: [:update, :destroy]

  def index
    categories = Category.order(created_at: :desc)
    render json: categories, status: :ok
  end

  def create
    category = Category.new(category_params)

    if category.save
      render json: category, status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: @category, status: :ok
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      head :no_content
    else
      render json: { errors: ['カテゴリの削除に失敗しました。'] }, status: :unprocessable_entity
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end