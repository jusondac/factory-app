class UnitBatch < ApplicationRecord
  belongs_to :product
  has_one :prepare, dependent: :destroy
  has_one :produce, dependent: :destroy

  enum :status, {
    preparation: 0,
    production: 1,
    testing: 2,
    packing: 3
  }

  validates :unit_id, presence: true, uniqueness: true
  validates :product_id, presence: true

  before_validation :generate_unit_id, on: :create

  scope :for_date, ->(date) { joins(:prepare).where(prepares: { prepare_date: date }) }
  scope :for_product, ->(product) { where(product: product) }

  def prepare_date
    prepare&.prepare_date
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "product_id", "status", "unit_id", "updated_at" ]
  end

   def self.ransackable_associations(auth_object = nil)
    [ "prepare", "product", "produce" ]
  end

  private

  def generate_unit_id
    return if unit_id.present?

    date_str = Date.current.strftime("%Y%m%d")

    # Find the next number for this date
    existing_count = UnitBatch.where("unit_id LIKE ?", "UNIT-#{date_str}-%").count

    self.unit_id = "UNIT-#{date_str}-#{existing_count + 1}"
  end
end
