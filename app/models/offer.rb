class Offer < ApplicationRecord
  belongs_to :item
  belongs_to :user

  enum status: { pending: 0, accepted: 1, rejected: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
