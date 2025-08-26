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
                  .per(10)

    # Auto-cancel outdated preparations in a single batch query
    outdated_ids = @prepares.select { |p| p.prepare_date < Date.current && (p.unchecked? || p.checking?) }.map(&:id)
    if outdated_ids.any?
      Prepare.where(id: outdated_ids).update_all(status: :cancelled, checked_by_id: nil)
      # Update in-memory objects
      @prepares.each { |p| p.status = "cancelled" if outdated_ids.include?(p.id) }
    end
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

      render :new, status: :unprocessable_entity
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

    case result
    when :completed
      redirect_to prepares_path, notice: "Preparation has been completed!"
    when :in_progress
      redirect_to checking_prepare_path(@prepare), notice: "Ingredient status updated."
    else
      redirect_to checking_prepare_path(@prepare), alert: "Unable to update ingredient status."
    end
  end

  def cancel
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
