class AdminPermission < ApplicationRecord
  belongs_to :user

  RESOURCES = %w[
    categories
    items
    orders
    users
    messages
    reports
  ].freeze

  validates :resource, presence: true, inclusion: { in: RESOURCES }
  validates :user_id, uniqueness: { scope: :resource }
end