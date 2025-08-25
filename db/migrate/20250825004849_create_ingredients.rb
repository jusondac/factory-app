class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end

    add_index :ingredients, :name
    add_index :ingredients, [:product_id, :created_at]
  end
end
