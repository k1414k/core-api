class Post < ApplicationRecord
  enum :status, { draft: 0, published: 1 }

  before_validation :set_slug

  validates :title, :slug, :excerpt, :content, presence: true
  validates :slug, uniqueness: true

  scope :published_ordered, -> {
    published.order(published_at: :desc, created_at: :desc)
  }

  private

  def set_slug
    self.slug = title.to_s.parameterize if slug.blank? && title.present?
  end
end