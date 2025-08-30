class PreparesController < ApplicationController
  before_action :set_prepare, only: [ :show, :check, :update_check, :checking, :cancel, :complete ]
  before_action :require_supervisor, only: [ :new, :create ]
  before_action :require_worker_for_check, only: [ :check, :checking, :update_check, :cancel, :complete ]

  def index
    # Build the query with all necessary includes upfront
    @q = Prepare.with_includes.ransack(params[:q])

    # Get paginated results
    @prepares = @q.result
                  .order(prepare_date: :desc, created_at: :desc)
                  .page(params[:page])
                  .per(5)

    # Auto-cancel outdated preparations using service
    PrepareService.auto_cancel_outdated_preparations(@prepares)
  end

  def show
    redirect_to checking_prepare_path(@prepare) if @prepare.checking? && Current.user&.can_check_prepares?
    # Preload ingredients with proper ordering to avoid N+1
    @prepare_ingredients = @prepare.prepare_ingredients.order(:ingredient_name)
    @presenter = PreparePresenter.new(@prepare)
  end

  def new
    @prepare = Prepare.new
    @products = Product.order(:name)
  end

  def create
    service = PrepareService.new(
      product_id: prepare_params[:product_id],
      prepare_date: prepare_params[:prepare_date],
      created_by: Current.user
    )

    if service.call
      redirect_to prepares_path, notice: "Preparation was successfully created."
    else
      @prepare = service.prepare || Prepare.new(prepare_params.except(:product_id))
      @prepare.temp_product_id = prepare_params[:product_id]
      @products = Product.order(:name)

      # Transfer service errors to prepare object for form display
      service.errors.each { |error| @prepare.errors.add(:base, error.message) }

      render :new, status: :unprocessable_content
    end
  end

  def check
    service = PrepareCheckingService.new(prepare: @prepare, user: Current.user)

    if service.start_checking
      redirect_to checking_prepare_path(@prepare), notice: "You are now checking this preparation."
    else
      redirect_to prepares_path, alert: "You cannot check this preparation."
    end
  end

  def checking
    # Preload ingredients with proper ordering to avoid N+1
    @prepare_ingredients = @prepare.prepare_ingredients.order(:ingredient_name)
  end

  def update_check
    service = PrepareCheckingService.new(
      prepare: @prepare,
      user: Current.user,
      prepare_ingredient_id: params[:prepare_ingredient_id]
    )

    result = service.toggle_ingredient_check

    respond_to do |format|
      case result
      when :completed
        format.html { redirect_to prepares_path, notice: "Preparation has been completed!" }
        format.json {
          render json: {
            success: true,
            all_completed: true,
            message: "Preparation has been completed!",
            ingredient: ingredient_data,
            progress: progress_data
          }
        }
      when :in_progress
        format.html { redirect_to checking_prepare_path(@prepare), notice: "Ingredient status updated." }
        format.json {
          render json: {
            success: true,
            all_completed: false,
            message: "Ingredient status updated.",
            ingredient: ingredient_data,
            progress: progress_data
          }
        }
      else
        format.html { redirect_to checking_prepare_path(@prepare), alert: "Unable to update ingredient status." }
        format.json {
          render json: {
            success: false,
            message: "Unable to update ingredient status."
          }, status: :unprocessable_content
        }
      end
    end
  end

  def cancel
    # Update notes if provided
    @prepare.update(notes: params[:notes]) if params[:notes].present?
    service = PrepareCheckingService.new(prepare: @prepare, user: Current.user)
    if service.cancel_checking
      redirect_to prepares_path, notice: "Preparation has been cancelled."
    else
      redirect_to prepares_path, alert: "You cannot cancel this preparation."
    end
  end

  def complete
    service = PrepareCheckingService.new(prepare: @prepare, user: Current.user)

    if service.complete_checking
      redirect_to prepares_path, notice: "Preparation has been completed!"
    else
      redirect_to checking_prepare_path(@prepare), alert: "You cannot complete this preparation."
    end
  end

  private

  def set_prepare
    # Preload associations to avoid N+1 queries
    @prepare = Prepare.includes(
      { unit_batch: :product },
      :created_by,
      :checked_by,
      :prepare_ingredients
    ).find(params[:id])
  end

  def prepare_params
    params.require(:prepare).permit(:product_id, :prepare_date, :notes)
  end

  def ingredient_data
    ingredient = @prepare.prepare_ingredients.find(params[:prepare_ingredient_id])
    {
      id: ingredient.id,
      ingredient_name: ingredient.ingredient_name,
      checked: ingredient.checked
    }
  end

  def progress_data
    total_count = @prepare.prepare_ingredients.count
    checked_count = @prepare.prepare_ingredients.checked.count
    {
      total_count: total_count,
      checked_count: checked_count,
      remaining_count: total_count - checked_count,
      percentage: total_count > 0 ? ((checked_count.to_f / total_count) * 100).round(1) : 0
    }
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
