class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]
  before_action :require_manager_or_head, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    # Set up Ransack search
    @q = Product.includes(:user, :ingredients).ransack(params[:q])

    # Get the results with pagination
    @products = @q.result
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(8)  # 8 items per page
  end

  def show
  end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)

    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    unless can_edit_product?
      redirect_to products_path, alert: "You can only edit your own products."
    end
  end

  def update
    unless can_edit_product?
      redirect_to products_path, alert: "You can only edit your own products."
      return
    end

    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    unless can_edit_product?
      redirect_to products_path, alert: "You can only delete your own products."
      return
    end

    @product.destroy
    redirect_to products_path, notice: "Product was successfully deleted."
  end

  def add_ingredient
    @product = Product.find(params[:id])

    unless can_edit_product?
      render json: { error: "You can only edit your own products." }, status: :forbidden
      return
    end

    @ingredient = @product.ingredients.build(ingredient_params)

    if @ingredient.save
      render json: {
        id: @ingredient.id,
        name: @ingredient.name,
        success: true
      }
    else
      render json: {
        errors: @ingredient.errors.full_messages,
        success: false
      }, status: :unprocessable_content
    end
  end

  def remove_ingredient
    @product = Product.find(params[:id])
    @ingredient = @product.ingredients.find(params[:ingredient_id])

    unless can_edit_product?
      render json: { error: "You can only edit your own products." }, status: :forbidden
      return
    end

    @ingredient.destroy
    render json: { success: true }
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :period_year, :period_month, :period_week, :period_day)
  end

  def ingredient_params
    params.require(:ingredient).permit(:name)
  end

  def require_manager_or_head
    unless current_user&.can_create_products?
      redirect_to root_path, alert: "Only managers and heads can manage products."
    end
  end

  def can_edit_product?
    current_user&.can_create_products? && (@product.user == current_user || current_user.head?)
  end

  def current_user
    Current.session&.user
  end
end
