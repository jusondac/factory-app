class AddMachineCheckToPackages < ActiveRecord::Migration[8.0]
  def change
    add_column :packages, :machine_check, :boolean, default: false
  end
end
