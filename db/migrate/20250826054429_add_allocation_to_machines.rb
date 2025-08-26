class AddAllocationToMachines < ActiveRecord::Migration[8.0]
  def change
    add_column :machines, :allocation, :integer
  end
end
