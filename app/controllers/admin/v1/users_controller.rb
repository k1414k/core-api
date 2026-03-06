class Admin::V1::UsersController < Admin::V1::BaseController
  before_action -> { authorize_admin_resource!(:users, :read) }, only: [:index]
  before_action :require_super_admin!, only: [:update_role, :update_permissions]
  before_action :set_user, only: [:update_role, :update_permissions]

  def index
    users = User.includes(:admin_permissions).order(created_at: :desc)

    render json: {
      current_user: serialize_current_user(current_user),
      users: users.map { |user| serialize_user(user) },
      permission_resources: AdminPermission::RESOURCES
    }, status: :ok
  end

  def update_role
    new_role = role_params[:role].to_s
    unless User.roles.key?(new_role)
      return render_unprocessable("不正な role です。")
    end

    if current_user.id == @user.id && new_role != "super_admin"
      return render_unprocessable("自分自身を super_admin 以外に変更できません。")
    end

    if @user.super_admin? && new_role != "super_admin"
      if User.where(role: User.roles[:super_admin]).count <= 1
        return render_unprocessable("最後の super_admin は変更できません。")
      end
    end

    ActiveRecord::Base.transaction do
      @user.update!(role: new_role)
      @user.admin_permissions.destroy_all if @user.user?
    end

    render json: {
      message: "role を更新しました。",
      user: serialize_user(@user.reload)
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.first || "role 更新に失敗しました。" },
           status: :unprocessable_entity
  end

  def update_permissions
    unless @user.admin?
      return render_unprocessable("権限設定できるのは admin ユーザーのみです。")
    end

    permissions = permissions_params[:permissions] || []
    invalid_resources = permissions.map { |p| p[:resource] } - AdminPermission::RESOURCES
    if invalid_resources.any?
      return render_unprocessable("不正な resource が含まれています。")
    end

    ActiveRecord::Base.transaction do
      @user.admin_permissions.destroy_all

      permissions.each do |permission|
        @user.admin_permissions.create!(
          resource: permission[:resource],
          can_read: ActiveModel::Type::Boolean.new.cast(permission[:can_read]),
          can_create: ActiveModel::Type::Boolean.new.cast(permission[:can_create]),
          can_update: ActiveModel::Type::Boolean.new.cast(permission[:can_update]),
          can_destroy: ActiveModel::Type::Boolean.new.cast(permission[:can_destroy])
        )
      end
    end

    render json: {
      message: "権限を更新しました。",
      user: serialize_user(@user.reload)
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.first || "権限更新に失敗しました。" },
           status: :unprocessable_entity
  end

  private

  def set_user
    @user = User.includes(:admin_permissions).find(params[:id])
  end

  def role_params
    params.require(:user).permit(:role)
  end

  def permissions_params
    params.permit(permissions: [:resource, :can_read, :can_create, :can_update, :can_destroy])
  end

  def serialize_current_user(user)
    {
      id: user.id,
      nickname: user.nickname,
      email: user.email,
      role: user.role
    }
  end

  def serialize_user(user)
    {
      id: user.id,
      nickname: user.nickname,
      email: user.email,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at,
      permissions: user.admin_permissions.order(:resource).map do |permission|
        {
          resource: permission.resource,
          can_read: permission.can_read,
          can_create: permission.can_create,
          can_update: permission.can_update,
          can_destroy: permission.can_destroy
        }
      end
    }
  end
end
