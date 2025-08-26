class CreateProduces < ActiveRecord::Migration[8.0]
  def change
    create_table :produces do |t|
      t.date :product_date, null: false
      t.string :product_id, null: false
      t.integer :status, default: 0, null: false
      t.references :unit_batch, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end

    add_index :produces, :product_id, unique: true
    add_index :produces, :product_date
  end
end
