class Package < ApplicationRecord
  # id: integer (PK)
  # package_date: date - not null
  # package_id: string - not null
  # status: integer - default: 0, not null
  # unit_batch_id: integer (FK) - not null
  # machine_id: integer (FK) - nullable
  # waste_quantity: integer - default: 0
  # created_at: datetime - not null
  # updated_at: datetime - not null

  # Indexes
  # index_packages_on_package_id (package_id) (unique)
  # index_packages_on_package_date (package_date)
  # index_packages_on_unit_batch_id (unit_batch_id) (unique)

  belongs_to :unit_batch
  belongs_to :machine, optional: true

  validates :package_date, presence: true
  validates :package_id, presence: true, uniqueness: true
  validates :unit_batch_id, uniqueness: true
  validates :waste_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :status, { unpackage: 0, packaging: 1, package: 2 }, default: :unpackage

  before_validation :generate_package_id, on: :create
  after_create :update_unit_batch_expiry_date

  scope :for_date, ->(date) { where(package_date: date) }
  scope :for_product, ->(product) { joins(:unit_batch).where(unit_batches: { product: product }) }
  scope :with_includes, -> { includes(unit_batch: :product) }

  # Delegate product to unit_batch
  delegate :product, to: :unit_batch, allow_nil: true

  # Delegate prepare to unit_batch
  delegate :prepare, to: :unit_batch, allow_nil: true

  # Delegate produce to unit_batch
  delegate :produce, to: :unit_batch, allow_nil: true

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "machine_id", "package_date", "package_id", "status", "unit_batch_id", "updated_at", "waste_quantity" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "machine", "unit_batch", "product"]
  end

  private

  def generate_package_id
    return if package_id.present?

    date_str = (package_date || Date.current).strftime("%Y%m%d")

    # Find the next number for this date
    existing_count = Package.where("package_id LIKE ?", "PACK-#{date_str}-%").count

    self.package_id = "PACK-#{date_str}-#{existing_count + 1}"
  end

  def update_unit_batch_expiry_date
    return unless unit_batch.present?

    expiry_date = unit_batch.calculate_expiry_date
    unit_batch.update_column(:expiry_date, expiry_date) if expiry_date.present?
  end
end
