class Produce < ApplicationRecord
  # id: integer (PK)
  # product_date: date - not null
  # product_id: string - not null
  # status: integer - default: 0, not null
  # unit_batch_id: integer (FK) - not null
  # created_at: datetime - not null
  # updated_at: datetime - not null

  # Indexes
  # index_produces_on_product_id (product_id) (unique)
  # index_produces_on_product_date (product_date)
  # index_produces_on_unit_batch_id (unit_batch_id) (unique)

  belongs_to :unit_batch

  validates :product_date, presence: true
  validates :product_id, presence: true, uniqueness: true
  validates :unit_batch_id, uniqueness: true

  enum :status, { unproduce: 0, producing: 1, produced: 2 }, default: :unproduce

  before_validation :generate_product_id, on: :create

  scope :for_date, ->(date) { where(product_date: date) }
  scope :for_product, ->(product) { joins(:unit_batch).where(unit_batches: { product: product }) }
  scope :with_includes, -> { includes(unit_batch: :product) }

  # Delegate product to unit_batch
  delegate :product, to: :unit_batch, allow_nil: true

  # Delegate prepare to unit_batch
  delegate :prepare, to: :unit_batch, allow_nil: true

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "product_date", "product_id", "status", "unit_batch_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "unit_batch" ]
  end

  private

  def generate_product_id
    return if product_id.present?

    date_str = (product_date || Date.current).strftime("%Y%m%d")

    # Find the next number for this date
    existing_count = Produce.where("product_id LIKE ?", "PROD-#{date_str}-%").count

    self.product_id = "PROD-#{date_str}-#{existing_count + 1}"
  end
end
