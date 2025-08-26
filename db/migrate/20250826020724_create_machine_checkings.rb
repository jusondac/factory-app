class CreateMachineCheckings < ActiveRecord::Migration[8.0]
  def change
    create_table :machine_checkings do |t|
      t.references :machine, null: false, foreign_key: true
      t.string :checking_name
      t.integer :checking_type
      t.text :checking_value

      t.timestamps
    end
  end
end
