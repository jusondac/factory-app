class UnitBatchesController < ApplicationController
  before_action :set_unit_batch, only: [ :show, :edit, :update, :destroy, :start_preparing ]
  before_action :require_supervisor_for_create, only: [ :new, :create ]
  before_action :require_supervisor_for_edit, only: [ :edit, :update, :destroy ]
  before_action :require_supervisor_for_start_preparing, only: [ :start_preparing ]

  def index
    # Set up Ransack search
    @q = UnitBatch.includes(:product, :prepare, :produce).ransack(params[:q])

    # Apply tab filter
    tab = params[:tab] || "today"
    @tab = tab

    base_query = case tab
    when "today"
      @q.result.today
    when "history"
      @q.result.history
    else
      @q.result
    end

    # Get the results with pagination
    @unit_batches = base_query
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(8)  # 8 items per page

    # Get products for filter dropdown
    @products = Product.all
  end

  def show
  end

  def new
    @unit_batch = UnitBatch.new
    @products = Product.all
  end

  def create
    @unit_batch = UnitBatch.new(unit_batch_params)

    if @unit_batch.save
      redirect_to @unit_batch, notice: "Unit batch was successfully created."
    else
      @products = Product.all
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @products = Product.all
  end

  def update
    if @unit_batch.update(unit_batch_params)
      redirect_to @unit_batch, notice: "Unit batch was successfully updated."
    else
      @products = Product.all
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @unit_batch.destroy
    redirect_to unit_batches_path, notice: "Unit batch was successfully deleted."
  end

  def start_preparing
    if @unit_batch.prepare.present?
      redirect_to @unit_batch, alert: "Preparation already exists for this unit batch."
      return
    end

    prepare = @unit_batch.build_prepare(
      prepare_date: Date.current,
      created_by: current_user
    )

    if prepare.save
      redirect_to @unit_batch, notice: "Preparation started successfully. Workers can now begin checking ingredients."
    else
      redirect_to @unit_batch, alert: "Failed to start preparation: #{prepare.errors.full_messages.join(', ')}"
    end
  end

  def quick_create
    unless current_user&.supervisor?
      redirect_back(fallback_location: root_path, alert: "Only supervisors can quick create unit batches.")
      return
    end

    # If product_id is provided (from product show page), use it
    # Otherwise, pick a random product (from unit batch index page)
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      redirect_path = product
    else
      product = Product.all.sample
      redirect_path = unit_batches_path(tab: "today")
    end

    unless product
      redirect_back(fallback_location: root_path, alert: "No products available to create unit batch.")
      return
    end

    # Generate random values for quick creation
    random_quantity = [ 50, 100, 150, 200, 250, 300 ].sample
    random_package_type = UnitBatch.package_types.keys.sample
    random_shift = UnitBatch.shifts.keys.sample

    @unit_batch = UnitBatch.new(
      product: product,
      quantity: random_quantity,
      package_type: random_package_type,
      shift: random_shift
    )

    if @unit_batch.save
      # Create a prepare record so it shows up in "today" tab
      prepare = @unit_batch.build_prepare(
        prepare_date: Date.current,
        created_by: current_user
      )
      prepare.save

      redirect_to redirect_path, notice: "Quick unit batch created successfully! #{@unit_batch.unit_id} for #{product.name} - #{random_quantity} units in #{random_package_type.humanize} for #{random_shift.humanize} shift."
    else
      redirect_to redirect_path, alert: "Failed to create unit batch: #{@unit_batch.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_unit_batch
    @unit_batch = UnitBatch.find(params[:id])
  end

  def unit_batch_params
    params.require(:unit_batch).permit(:product_id, :quantity, :package_type, :shift)
  end

  def current_user
    Current.session&.user
  end

  def require_supervisor_for_create
    unless current_user&.can_create_unit_batches?
      redirect_to unit_batches_path, alert: "You don't have permission to create unit batches."
    end
  end

  def require_supervisor_for_edit
    unless current_user&.can_create_unit_batches?
      redirect_to unit_batches_path, alert: "You don't have permission to edit unit batches."
    end
  end

  def require_supervisor_for_start_preparing
    unless current_user&.can_start_preparing?
      redirect_to @unit_batch, alert: "You don't have permission to start preparing."
    end
  end
end
