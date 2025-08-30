class Product < ApplicationRecord
  belongs_to :user
  has_many :ingredients, dependent: :destroy
  has_many :unit_batches, dependent: :destroy
  has_many :prepares, through: :unit_batches

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :user, presence: true
  validates :product_code, presence: true, uniqueness: true
  validates :period_year, numericality: { greater_than: 0 }, allow_nil: true
  validates :period_month, numericality: { in: 1..12 }, allow_nil: true
  validates :period_week, numericality: { in: 1..52 }, allow_nil: true
  validates :period_day, numericality: { in: 1..365 }, allow_nil: true

  before_validation :generate_product_code, on: :create
  before_validation :set_random_periods, on: :create

  scope :by_manager, ->(user) { where(user: user) if user&.can_create_products? }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "name", "period_day", "period_month", "period_week", "period_year", "product_code", "updated_at", "user_id" ]
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

  def set_random_periods
    # Only set random periods if none are provided
    if period_year.blank? && period_month.blank? && period_week.blank? && period_day.blank?
      # Generate random shelf life periods
      self.period_year = rand(1..3)          # 1-3 years
      self.period_month = rand(1..12)        # 1-12 months
      self.period_week = rand(1..52)         # 1-52 weeks
      self.period_day = rand(1..365)         # 1-365 days
    end
  end
end
