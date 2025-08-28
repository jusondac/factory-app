class AddFieldsToUnitBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :unit_batches, :quantity, :integer
    add_column :unit_batches, :package_type, :integer
    add_column :unit_batches, :shift, :integer
    add_column :unit_batches, :batch_code, :string
  end
end
