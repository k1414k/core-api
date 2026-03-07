class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 8 }

  has_many :items
  has_one_attached :image

  validate :image_type
  validate :image_size

  private

  def image_type
    return unless image.attached?

    unless image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:image, "はJPEG/PNG/WebPのみ対応しています")
    end
  end

  def image_size
    return unless image.attached?

    if image.blob.byte_size > 5.megabytes
      errors.add(:image, "は5MB以下にしてください")
    end
  end
end

