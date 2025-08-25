class Prepare < ApplicationRecord
  belongs_to :product
  belongs_to :created_by, class_name: "User"
  belongs_to :checked_by, class_name: "User", optional: true
  has_many :prepare_ingredients, dependent: :destroy

  validates :prepare_date, presence: true
  validates :prepare_id, presence: true, uniqueness: true
  validates :product_id, uniqueness: { scope: :prepare_date, message: "can only have one preparation per day" }

  enum :status, { unchecked: 0, checking: 1, checked: 2, cancelled: 3 }, default: :unchecked

  before_validation :generate_prepare_id, on: :create
  after_create :create_prepare_ingredients

  scope :for_date, ->(date) { where(prepare_date: date) }
  scope :for_product, ->(product) { where(product: product) }

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

    date_str = prepare_date&.strftime("%Y%m%d")
    return unless date_str

    # Find the next number for this date
    existing_count = Prepare.where("prepare_id LIKE ?", "PRP-#{date_str}-%").count

    self.prepare_id = "PRP-#{date_str}-#{existing_count}"
  end

  def create_prepare_ingredients
    product.ingredients.find_each do |ingredient|
      prepare_ingredients.create!(
        ingredient_name: ingredient.name,
        checked: false
      )
    end
  end
end
