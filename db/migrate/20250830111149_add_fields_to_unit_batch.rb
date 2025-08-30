class AddFieldsToUnitBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :unit_batches, :waste_quantity, :integer
    add_column :unit_batches, :expiry_date, :datetime
  end
end
