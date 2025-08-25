class UnitBatch < ApplicationRecord
  belongs_to :product
  has_one :prepare, dependent: :destroy

  validates :unit_id, presence: true, uniqueness: true
  validates :product_id, presence: true

  before_validation :generate_unit_id, on: :create

  scope :for_date, ->(date) { joins(:prepare).where(prepares: { prepare_date: date }) }
  scope :for_product, ->(product) { where(product: product) }

  def prepare_date
    prepare&.prepare_date
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
