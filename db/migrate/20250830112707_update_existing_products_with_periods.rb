class UpdateExistingProductsWithPeriods < ActiveRecord::Migration[8.0]
  def up
    # Update existing products that don't have period values
    # Use update_columns to bypass validations since we're only updating period fields
    Product.where(period_year: nil, period_month: nil, period_week: nil, period_day: nil).find_each do |product|
      product.update_columns(
        period_year: rand(1..3),          # 1-3 years
        period_month: rand(1..12),        # 1-12 months
        period_week: rand(1..52),         # 1-52 weeks
        period_day: rand(1..365)          # 1-365 days
      )
    end
  end

  def down
    # Optionally, you can reset the period fields to nil
    # Product.update_all(period_year: nil, period_month: nil, period_week: nil, period_day: nil)
  end
end
