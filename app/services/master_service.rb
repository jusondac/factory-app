class MasterService
  include ActiveModel::Model

  attr_accessor :unit_batch, :user

  validates :user, presence: true

  def initialize(user: nil)
    @user = user
  end

  # Create a new unit batch
  def create_unit_batch(product_id:, quantity:, package_type:, shift:)
    unit_batch = UnitBatch.new(
      product_id: product_id,
      quantity: quantity,
      package_type: package_type,
      shift: shift
    )

    if unit_batch.save
      { success: true, unit_batch: unit_batch, message: "Unit batch created successfully" }
    else
      { success: false, errors: unit_batch.errors.full_messages }
    end
  end

  # Move unit batch to preparation phase (create prepare record if not exists)
  def move_to_prepare(unit_batch_id:)
    return { success: false, error: "User is required" } unless user

    unit_batch = UnitBatch.find_by(id: unit_batch_id)
    return { success: false, error: "Unit batch not found" } unless unit_batch

    if unit_batch.prepare.present?
      return { success: true, message: "Unit batch is already in preparation phase" }
    end

    prepare = unit_batch.build_prepare(
      prepare_date: Date.current,
      created_by: user
    )

    if prepare.save
      { success: true, message: "Unit batch moved to preparation phase" }
    else
      { success: false, errors: prepare.errors.full_messages }
    end
  end

  # Move unit batch to production phase
  def move_to_production(unit_batch_id:)
    unit_batch = UnitBatch.find_by(id: unit_batch_id)
    return { success: false, error: "Unit batch not found" } unless unit_batch

    unless unit_batch.preparation?
      return { success: false, error: "Unit batch must be in preparation phase to move to production" }
    end

    ActiveRecord::Base.transaction do
      unit_batch.update!(status: :production)

      if unit_batch.produce.present?
        { success: true, message: "Unit batch moved to production phase" }
      else
        unit_batch.create_produce!(product_date: Date.current)
        { success: true, message: "Unit batch moved to production phase and produce record created" }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: "Failed to move to production: #{e.message}" }
  end

  # Move unit batch to package phase
  def move_to_package(unit_batch_id:)
    unit_batch = UnitBatch.find_by(id: unit_batch_id)
    return { success: false, error: "Unit batch not found" } unless unit_batch

    unless unit_batch.production?
      return { success: false, error: "Unit batch must be in production phase to move to package" }
    end

    ActiveRecord::Base.transaction do
      unit_batch.update!(status: :packing)

      if unit_batch.package.present?
        { success: true, message: "Unit batch moved to package phase" }
      else
        unit_batch.create_package!(
          package_date: Date.current,
          waste_quantity: 0
        )
        { success: true, message: "Unit batch moved to package phase and package record created" }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: "Failed to move to package: #{e.message}" }
  end

  # Undo to previous phase
  def undo(unit_batch_id:)
    unit_batch = UnitBatch.find_by(id: unit_batch_id)
    return { success: false, error: "Unit batch not found" } unless unit_batch

    case unit_batch.status
    when "packing"
      undo_to_production(unit_batch)
    when "production", "testing"
      undo_to_preparation(unit_batch)
    when "preparation"
      { success: false, error: "Cannot undo from preparation phase - this is the initial phase" }
    else
      { success: false, error: "Cannot undo from current status: #{unit_batch.status}" }
    end
  end

  # Get information about a unit batch
  def get_unit_batch_info(unit_batch_id:)
    unit_batch = UnitBatch.find_by(id: unit_batch_id)
    return { success: false, error: "Unit batch not found" } unless unit_batch

    {
      success: true,
      unit_batch: {
        id: unit_batch.id,
        unit_id: unit_batch.unit_id,
        batch_code: unit_batch.batch_code,
        status: unit_batch.status,
        product_name: unit_batch.product&.name,
        quantity: unit_batch.quantity,
        package_type: unit_batch.package_type,
        shift: unit_batch.shift,
        has_prepare: unit_batch.prepare.present?,
        has_produce: unit_batch.produce.present?,
        has_package: unit_batch.package.present?
      }
    }
  end
  def list_unit_batches(page: 1, per_page: 10)
    unit_batches = UnitBatch.includes(:product)
                           .order(created_at: :desc)
                           .page(page)
                           .per(per_page)

    {
      success: true,
      unit_batches: unit_batches.map do |ub|
        {
          id: ub.id,
          unit_id: ub.unit_id,
          batch_code: ub.batch_code,
          status: ub.status,
          product_name: ub.product&.name,
          quantity: ub.quantity,
          created_at: ub.created_at
        }
      end,
      pagination: {
        current_page: unit_batches.current_page,
        total_pages: unit_batches.total_pages,
        total_count: unit_batches.total_count
      }
    }
  end

  private

  def undo_to_production(unit_batch)
    ActiveRecord::Base.transaction do
      unit_batch.update!(status: :production)
      unit_batch.package&.destroy!
      { success: true, message: "Undid to production phase" }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: "Failed to undo: #{e.message}" }
  end

  def undo_to_preparation(unit_batch)
    ActiveRecord::Base.transaction do
      unit_batch.update!(status: :preparation)
      unit_batch.produce&.destroy!
      { success: true, message: "Undid to preparation phase" }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: "Failed to undo: #{e.message}" }
  end
end
