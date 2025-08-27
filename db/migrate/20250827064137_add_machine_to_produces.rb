class AddMachineToProduces < ActiveRecord::Migration[8.0]
  def change
    add_reference :produces, :machine, null: true, foreign_key: true
    add_column :produces, :machine_check, :boolean, default: false
  end
end
