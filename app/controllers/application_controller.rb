class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  
  before_action :config_permitted_params, :remove_internal_devise_params, if: :devise_controller?

  protected
  def require_admin! #管理者権限必要操作はbefore_actionで必ず指定すること
    head :forbidden unless current_user&.admin? || current_user&.super_admin?
  end

  def config_permitted_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :nickname])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :nickname, :password, :password_confirmation, :current_password])
  end

  def remove_internal_devise_params
    params.delete(:registration)
    params.delete(:session)
  end
end
