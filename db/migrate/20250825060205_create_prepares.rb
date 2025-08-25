class CreatePrepares < ActiveRecord::Migration[8.0]
  def change
    create_table :prepares do |t|
      t.references :product, null: false, foreign_key: true
      t.date :prepare_date, null: false
      t.string :prepare_id, null: false
      t.integer :status, default: 0
      t.references :checked_by, null: true, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :prepares, [ :product_id, :prepare_date ], unique: true
    add_index :prepares, :prepare_id, unique: true
  end
end
