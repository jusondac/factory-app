class Prepare < ApplicationRecord
  belongs_to :unit_batch
  belongs_to :created_by, class_name: "User"
  belongs_to :checked_by, class_name: "User", optional: true
  has_many :prepare_ingredients, dependent: :destroy

  validates :prepare_date, presence: true
  validates :prepare_id, presence: true, uniqueness: true
  validates :unit_batch_id, uniqueness: true

  enum :status, { unchecked: 0, checking: 1, checked: 2, cancelled: 3 }, default: :unchecked

  before_validation :generate_prepare_id, on: :create
  after_create :create_prepare_ingredients

  scope :for_date, ->(date) { where(prepare_date: date) }
  scope :for_product, ->(product) { joins(:unit_batch).where(unit_batches: { product: product }) }

  # Delegate product to unit_batch
  delegate :product, to: :unit_batch, allow_nil: true

  # Delegate product_id to unit_batch for form compatibility
  def product_id
    unit_batch&.product_id || @temp_product_id
  end

  # Allow setting product_id for form handling (virtual attribute)
  attr_accessor :temp_product_id

  def product_id=(value)
    @temp_product_id = value
  end

  def can_be_checked_by?(user)
    user.worker? && status != :checked && status != :cancelled
  end

  def can_be_created_by?(user)
    user.supervisor?
  end

  def all_ingredients_checked?
    prepare_ingredients.exists? && prepare_ingredients.unchecked.empty?
  end

  def checking_progress
    return "0/0" unless prepare_ingredients.exists?
    total = prepare_ingredients.count
    checked_count = prepare_ingredients.checked.count
    "#{checked_count}/#{total}"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "checked_by_id", "created_at", "created_by_id", "id", "id_value", "prepare_date", "prepare_id", "status", "unit_batch_id", "updated_at" ]
  end

   def self.ransackable_associations(auth_object = nil)
    ["checked_by", "created_by", "prepare_ingredients", "unit_batch"]
  end

  def clickable?
    prepare_date >= Date.current
  end

  def should_be_cancelled?
    prepare_date < Date.current && (unchecked? || checking?)
  end

  def auto_cancel_if_needed!
    update!(status: :cancelled) if should_be_cancelled?
  end

  private

  def generate_prepare_id
    return if prepare_id.present?

    date_str = prepare_date.strftime("%Y%m%d")

    # Find the next number for this date
    existing_count = Prepare.where("prepare_id LIKE ?", "PRP-#{date_str}-%").count

    self.prepare_id = "PRP-#{date_str}-#{existing_count + 1}"
  end

  def create_prepare_ingredients
    unit_batch.product.ingredients.find_each do |ingredient|
      prepare_ingredients.create!(
        ingredient_name: ingredient.name,
        checked: false
      )
    end
  end
end
