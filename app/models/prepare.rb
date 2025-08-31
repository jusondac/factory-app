class Prepare < ApplicationRecord
  # id: integer (PK)
  # prepare_date: date - not null
  # prepare_id: string - not null
  # status: integer - default: 0
  # checked_by_id: integer (FK)
  # created_by_id: integer (FK) - not null
  # created_at: datetime - not null
  # updated_at: datetime - not null
  # unit_batch_id: integer (FK) - not null
  # prepare_ingredients_count: integer - default: 0
  # checked_ingredients_count: integer - default: 0

  # Indexes
  # index_prepares_on_unit_batch_id (unit_batch_id)
  # index_prepares_on_prepare_id (prepare_id) (unique)
  # index_prepares_on_created_by_id (created_by_id)
  # index_prepares_on_checked_by_id (checked_by_id)

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
  scope :with_includes, -> { includes(unit_batch: :product, created_by: [], checked_by: [], prepare_ingredients: []) }
  scope :outdated_and_incomplete, -> { where(prepare_date: ...Date.current).where(status: [ :unchecked, :checking ]) }

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
    prepare_ingredients_count > 0 && checked_ingredients_count == prepare_ingredients_count
  end

  def update_checked_ingredients_count
    update_column(:checked_ingredients_count, prepare_ingredients.checked.count)
  end

  def checking_progress
    @checking_progress ||= "#{checked_ingredients_count}/#{prepare_ingredients_count}"
  end

  def checking_percentage
    @checking_percentage ||= begin
      total = prepare_ingredients_count
      return 0 if total.zero?

      checked_count = checked_ingredients_count
      (checked_count.to_f / total * 100).round(1)
    end
  end

  def update_prepare_status_to_check
    update(status: :checked)
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "checked_by_id", "created_at", "created_by_id", "id", "id_value", "notes", "prepare_date", "prepare_id", "status", "unit_batch_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "checked_by", "created_by", "prepare_ingredients", "unit_batch" ]
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
    ingredients = unit_batch.product.ingredients
    created_ingredients = []

    ingredients.find_each do |ingredient|
      created_ingredients << prepare_ingredients.create!(
        ingredient_name: ingredient.name,
        checked: false
      )
    end

    # Counter cache is automatically updated by Rails for prepare_ingredients_count
    # But we need to manually set checked_ingredients_count since all are unchecked
    update_column(:checked_ingredients_count, 0)
  end
end
