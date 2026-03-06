class User < ActiveRecord::Base
  has_many :messages, dependent: :destroy
  has_many :items
  has_many :buy_orders, class_name: "Order", foreign_key: :buyer_id
  has_many :sell_orders, class_name: "Order", foreign_key: :seller_id
  has_many :favorites, dependent: :destroy
  has_many :favorite_items, through: :favorites, source: :item
  has_many :addresses, dependent: :destroy

  has_many :admin_permissions, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include DeviseTokenAuth::Concerns::User

  before_validation :create_nickname, on: :create

  has_one_attached :avatar

  validates :nickname, presence: true, uniqueness: true, length: { minimum: 2, maximum: 10 }

  enum role: { user: 0, admin: 1, super_admin: 2 }

  def favorited?(item)
    favorites.exists?(item_id: item.id)
  end

  def can_admin?(resource, action)
    return true if super_admin?
    return false unless admin?

    permission = admin_permissions.find_by(resource: resource.to_s)
    return false unless permission

    case action.to_sym
    when :read
      permission.can_read?
    when :create
      permission.can_create?
    when :update
      permission.can_update?
    when :destroy
      permission.can_destroy?
    else
      false
    end
  end

  private

  def create_nickname
    return if nickname.present?

    loop do
      self.nickname = "ユーザー##{SecureRandom.hex(2)}"
      break unless User.exists?(nickname: nickname)
    end
  end
end