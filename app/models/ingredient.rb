class Ingredient < ApplicationRecord
  belongs_to :product

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :product, presence: true

  delegate :user, to: :product
end
