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

  enum :package_type, {
    box: 0,
    bottle: 1,
    pouch: 2,
    can: 3,
    jar: 4,
    sachet: 5,
    pack: 6,
    cup: 7,
    tube: 8,
    bucket: 9
  }

  enum :shift, {
    morning: 0,
    afternoon: 1,
    night: 2
  }

  validates :unit_id, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :package_type, presence: true
  validates :shift, presence: true
  validates :batch_code, presence: true, uniqueness: true

  before_validation :generate_unit_id, on: :create
  before_validation :generate_batch_code, on: :create

  scope :for_date, ->(date) { joins(:prepare).where(prepares: { prepare_date: date }) }
  scope :for_product, ->(product) { where(product: product) }

  def prepare_date
    prepare&.prepare_date
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "batch_code", "created_at", "id", "id_value", "package_type", "product_id", "quantity", "shift", "status", "unit_id", "updated_at" ]
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

  def generate_batch_code
    return if batch_code.present? || product.blank?

    date_str = Date.current.strftime("%Y%m%d")
    shift_code = shift&.upcase&.first || "M"
    line_code = "L01" # Default line, will be updated when machine is assigned
    
    # Find the next sequence number for this combination
    pattern = "#{product.product_code}-#{date_str}-#{shift_code}-%-"
    existing_count = UnitBatch.where("batch_code LIKE ?", pattern).count
    seq = (existing_count + 1).to_s.rjust(3, '0')
    
    self.batch_code = "#{product.product_code}-#{date_str}-#{shift_code}-#{line_code}-#{seq}"
  end

  public

  def update_batch_code_with_line(machine_line)
    return unless batch_code.present? && product.present?

    parts = batch_code.split('-')
    if parts.length == 5
      line_code = "L#{machine_line.to_s.rjust(2, '0')}"
      parts[3] = line_code
      update_column(:batch_code, parts.join('-'))
    end
  end
end
