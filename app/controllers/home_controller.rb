class HomeController < ApplicationController
  def index
    if Current.session&.user&.can_create_products?
      # Dashboard data for managers and heads
      @total_products = Product.count
      @my_products = Current.session.user.products
      @recent_products = Product.includes(:user, :ingredients).order(created_at: :desc).limit(5)
      @total_ingredients = Ingredient.count
      @products_by_role = Product.joins(:user).group("users.role").count
      @recent_activity = Product.includes(:user).order(updated_at: :desc).limit(10)

      # Statistics
      @avg_ingredients = @total_products > 0 ? (@total_ingredients.to_f / @total_products).round(1) : 0
      @products_this_week = Product.where(created_at: 1.week.ago..Time.current).count
      @my_products_count = @my_products.count
      @team_products_count = @total_products - @my_products_count
    else
      # Basic view for other roles
      @recent_products = Product.includes(:user, :ingredients).order(created_at: :desc).limit(3)
    end
  end
end
