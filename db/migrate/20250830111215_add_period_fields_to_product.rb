class AddPeriodFieldsToProduct < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :period_year, :integer
    add_column :products, :period_month, :integer
    add_column :products, :period_week, :integer
    add_column :products, :period_day, :integer
  end
end
