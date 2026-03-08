class Bid < ApplicationRecord
  belongs_to :item
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
