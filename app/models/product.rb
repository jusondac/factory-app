class Product < ApplicationRecord
  belongs_to :user
  has_many :ingredients, dependent: :destroy
  has_many :unit_batches, dependent: :destroy
  has_many :prepares, through: :unit_batches

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :user, presence: true
  validates :product_code, presence: true, uniqueness: true

  before_validation :generate_product_code, on: :create

  scope :by_manager, ->(user) { where(user: user) if user&.can_create_products? }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "name", "product_code", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "ingredients", "prepares", "unit_batches", "user" ]
  end

  private

  def generate_product_code
    return if product_code.present?

    loop do
      self.product_code = "PRD#{SecureRandom.hex(3).upcase}"
      break unless Product.exists?(product_code: product_code)
    end
  end
end
