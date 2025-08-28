class AddLineToMachines < ActiveRecord::Migration[8.0]
  def change
    add_column :machines, :line, :integer
  end
end
