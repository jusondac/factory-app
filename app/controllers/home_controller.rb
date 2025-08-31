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

      # Produce statistics with optimized queries
      @total_produces = Produce.count
      @produces_today = Produce.where(product_date: Date.current).count
      @produces_this_week = Produce.where(product_date: 1.week.ago..Date.current).count
      @produces_completed_today = Produce.where(product_date: Date.current, status: :produced).count
      @produces_by_status = Produce.group(:status).count
      @produces_by_date = Produce.where(product_date: 1.month.ago..Date.current).group(:product_date).count
      @recent_produces = Produce.includes(unit_batch: :product).order(created_at: :desc).limit(5)

      # Statistics
      @avg_ingredients = @total_products > 0 ? (@total_ingredients.to_f / @total_products).round(1) : 0
      @products_this_week = Product.where(created_at: 1.week.ago..Time.current).count
      @my_products_count = @my_products.count
      @team_products_count = @total_products - @my_products_count
    elsif Current.session&.user&.can_view_produces?
      # Dashboard for supervisors and workers
      @recent_products = Product.includes(:user, :ingredients).order(created_at: :desc).limit(3)
      @recent_produces = Produce.includes(unit_batch: :product).order(created_at: :desc).limit(5)
      @my_produces_today = Produce.where(product_date: Date.current)
      @produces_in_progress = Produce.where(status: :producing).count

      # Unit Batch Statistics with optimized queries
      @total_unit_batches = UnitBatch.count
      @unit_batches_today = UnitBatch.joins(:prepare).where(prepares: { prepare_date: Date.current }).count
      @unit_batches_this_week = UnitBatch.joins(:prepare).where(prepares: { prepare_date: 1.week.ago..Date.current }).count
      @unit_batches_by_status = UnitBatch.group(:status).count
      @unit_batches_by_date = UnitBatch.joins(:prepare).where(prepares: { prepare_date: 1.month.ago..Date.current }).group("prepares.prepare_date").count

      # Prepare Statistics with optimized queries
      @total_prepares = Prepare.count
      @prepares_today = Prepare.where(prepare_date: Date.current).count
      @prepares_this_week = Prepare.where(prepare_date: 1.week.ago..Date.current).count
      @prepares_checked_today = Prepare.where(prepare_date: Date.current, status: :checked).count
      @prepares_pending = Prepare.where(status: [ :unchecked, :checking ]).count
      @prepares_by_status = Prepare.group(:status).count
      @prepares_by_date = Prepare.where(prepare_date: 1.month.ago..Date.current).group(:prepare_date).count
      @recent_prepares = Prepare.includes(:unit_batch, :created_by, :checked_by).order(created_at: :desc).limit(5)

      # Production Statistics with optimized queries
      @total_produces = Produce.count
      @produces_today = Produce.where(product_date: Date.current).count
      @produces_this_week = Produce.where(product_date: 1.week.ago..Date.current).count
      @produces_completed_today = Produce.where(product_date: Date.current, status: :produced).count
      @produces_by_status = Produce.group(:status).count
      @produces_by_date = Produce.where(product_date: 1.month.ago..Date.current).group(:product_date).count
      @recent_produces = Produce.includes(unit_batch: :product).order(created_at: :desc).limit(5)
    else
      # Basic view for other roles
      @recent_products = Product.includes(:user, :ingredients).order(created_at: :desc).limit(3)
    end
  end
end
