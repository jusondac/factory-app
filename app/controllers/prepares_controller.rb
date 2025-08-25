class PreparesController < ApplicationController
  before_action :set_prepare, only: [ :show, :check, :update_check, :checking ]
  before_action :require_supervisor, only: [ :new, :create ]
  before_action :require_worker_for_check, only: [ :check, :checking, :update_check ]

  def index
    @prepares = Prepare.includes(:product, :created_by, :checked_by, :prepare_ingredients)
                      .order(prepare_date: :desc, created_at: :desc)

    # Auto-cancel old unchecked/checking prepares
    @prepares.each(&:auto_cancel_if_needed!)

    # Reload to get updated statuses
    @prepares = @prepares.reload
  end

  def show
    @prepare_ingredients = @prepare.prepare_ingredients.order(:ingredient_name)
  end

  def new
    @prepare = Prepare.new
    @products = Product.all.order(:name)
  end

  def create
    @prepare = Prepare.new(prepare_params)
    @prepare.created_by = Current.user

    if @prepare.save
      redirect_to prepares_path, notice: "Prepare was successfully created."
    else
      @products = Product.all.order(:name)
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
