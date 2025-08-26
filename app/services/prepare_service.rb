class PrepareService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :product_id, :integer
  attribute :prepare_date, :date
  attribute :created_by

  validates :product_id, presence: true
  validates :prepare_date, presence: true
  validates :created_by, presence: true

  def initialize(attributes = {})
    super
    @product = Product.find_by(id: product_id) if product_id.present?
  end

  def call
    return false unless valid?
    return false if preparation_already_exists?

    ActiveRecord::Base.transaction do
      create_unit_batch!
      create_prepare!
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def preparation_already_exists?
    existing_preparation = UnitBatch.joins(:prepare)
                                   .where(product: @product, prepares: { prepare_date: prepare_date })
                                   .exists?
    
    if existing_preparation
      errors.add(:base, "A preparation for this product on this date already exists.")
      return true
    end
    
    false
  end

  def unit_batch
    @unit_batch
  end

  def prepare
    @prepare
  end

  private

  def create_unit_batch!
    @unit_batch = UnitBatch.create!(
      product: @product,
      status: :preparation
    )
  end

  def create_prepare!
    @prepare = Prepare.create!(
      unit_batch: @unit_batch,
      prepare_date: prepare_date,
      created_by: created_by
    )
  end
end
