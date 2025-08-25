class IngredientsController < ApplicationController
  before_action :set_product
  before_action :set_ingredient, only: [ :edit, :update, :destroy ]
  before_action :require_manager_or_head
  before_action :require_product_owner

  def index
    @ingredients = @product.ingredients.order(:name)
  end

  def new
    @ingredient = @product.ingredients.build
  end

  def create
    @ingredient = @product.ingredients.build(ingredient_params)

    if @ingredient.save
      redirect_to @product, notice: "Ingredient was successfully added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @ingredient.update(ingredient_params)
      redirect_to @product, notice: "Ingredient was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @ingredient.destroy
    redirect_to @product, notice: "Ingredient was successfully removed."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_ingredient
    @ingredient = @product.ingredients.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name)
  end

  def require_manager_or_head
    unless current_user&.can_create_products?
      redirect_to root_path, alert: "Only managers and heads can manage ingredients."
    end
  end

  def require_product_owner
    unless @product.user == current_user || current_user.head?
      redirect_to products_path, alert: "You can only manage ingredients for your own products."
    end
  end

  def current_user
    Current.session&.user
  end
end
