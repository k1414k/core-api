class Admin::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  private

  def require_admin_user!
    return if current_user&.admin? || current_user&.super_admin?

    render_forbidden("管理者のみアクセスできます。")
  end

  def authorize_admin_resource!(resource, action)
    return if current_user&.can_admin?(resource, action)

    render_forbidden("#{resource} に対する #{action} 権限がありません。")
  end

  def require_super_admin!
    return if current_user&.super_admin?

    render_forbidden("super_admin のみ実行できます。")
  end

  def render_forbidden(message = "権限がありません。")
    render json: { error: message }, status: :forbidden
  end

  def render_unprocessable(message)
    render json: { error: message }, status: :unprocessable_entity
  end
end
