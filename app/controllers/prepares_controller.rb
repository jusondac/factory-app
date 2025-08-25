class PreparesController < ApplicationController
  before_action :set_prepare, only: [ :show, :check, :update_check, :checking, :cancel ]
  before_action :require_supervisor, only: [ :new, :create ]
  before_action :require_worker_for_check, only: [ :check, :checking, :update_check, :cancel ]

  def index
    # Set up Ransack search
    @q = Prepare.includes({ unit_batch: :product }, :created_by, :checked_by, :prepare_ingredients)
                .ransack(params[:q])

    # Get the results and order them
    @prepares = @q.result
                  .order(prepare_date: :desc, created_at: :desc)
                  .page(params[:page])
                  .per(10)  # 10 items per page

    # Auto-cancel old unchecked/checking prepares (only for current page to avoid performance issues)
    @prepares.each(&:auto_cancel_if_needed!)

    # Note: No need to reload since Kaminari handles the pagination
  end

  def show
    @prepare_ingredients = @prepare.prepare_ingredients.order(:ingredient_name)
  end

  def new
    @prepare = Prepare.new
    @products = Product.all.order(:name)
  end

  def create
    product = Product.find(prepare_params[:product_id])

    # Check if there's already a unit batch for this product on this date
    existing_unit_batch = UnitBatch.joins(:prepare)
                                   .where(product: product, prepares: { prepare_date: prepare_params[:prepare_date] })
                                   .first

    if existing_unit_batch
      redirect_to prepares_path, alert: "A preparation for this product on this date already exists."
      return
    end

    # Create UnitBatch first
    @unit_batch = UnitBatch.new(product: product, status: :preparation)

    if @unit_batch.save
      # Then create Prepare
      @prepare = Prepare.new(prepare_params.except(:product_id))
      @prepare.unit_batch = @unit_batch
      @prepare.created_by = Current.user

      if @prepare.save
        redirect_to prepares_path, notice: "Preparation was successfully created."
      else
        @unit_batch.destroy # Clean up if prepare creation fails
        @products = Product.all.order(:name)
        # Set the product_id for form redisplay
        @prepare.temp_product_id = prepare_params[:product_id]
        render :new, status: :unprocessable_entity
      end
    else
      @products = Product.all.order(:name)
      @prepare = Prepare.new(prepare_params.except(:product_id))
      # Set the product_id for form redisplay
      @prepare.temp_product_id = prepare_params[:product_id]
      render :new, status: :unprocessable_entity
    end
  end

  def check
    if @prepare.can_be_checked_by?(Current.user)
      @prepare.update(status: :checking, checked_by: Current.user)
      redirect_to checking_prepare_path(@prepare), notice: "You are now checking this preparation."
    else
      redirect_to prepares_path, alert: "You cannot check this preparation."
    end
  end

  def checking
    @prepare_ingredients = @prepare.prepare_ingredients.order(:ingredient_name)
  end

  def update_check
    prepare_ingredient = @prepare.prepare_ingredients.find(params[:prepare_ingredient_id])
    prepare_ingredient.toggle_checked!

    # Check if all ingredients are checked
    if @prepare.all_ingredients_checked?
      @prepare.update(status: :checked)
      redirect_to prepares_path, notice: "Preparation has been completed!"
    else
      redirect_to checking_prepare_path(@prepare), notice: "Ingredient status updated."
    end
  end

  def cancel
    if @prepare.status == "checking" && @prepare.checked_by == Current.user
      @prepare.update(status: :cancelled, checked_by: nil)
      redirect_to prepares_path, notice: "Preparation has been cancelled."
    else
      redirect_to prepares_path, alert: "You cannot cancel this preparation."
    end
  end

  private

  def set_prepare
    @prepare = Prepare.find(params[:id])
  end

  def prepare_params
    params.require(:prepare).permit(:product_id, :prepare_date)
  end

  def require_supervisor
    unless Current.user&.can_create_prepares?
      redirect_to prepares_path, alert: "Only supervisors can create preparations."
    end
  end

  def require_worker_for_check
    unless Current.user&.can_check_prepares?
      redirect_to prepares_path, alert: "Only workers can check preparations."
    end
  end
end
