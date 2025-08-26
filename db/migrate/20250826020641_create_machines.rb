class CreateMachines < ActiveRecord::Migration[8.0]
  def change
    create_table :machines do |t|
      t.string :name
      t.string :serial_number
      t.integer :status

      t.timestamps
    end
  end
end
