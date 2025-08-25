class Product < ApplicationRecord
  belongs_to :user
  has_many :ingredients, dependent: :destroy
  has_many :unit_batches, dependent: :destroy
  has_many :prepares, through: :unit_batches

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :user, presence: true

  scope :by_manager, ->(user) { where(user: user) if user&.can_create_products? }
end
