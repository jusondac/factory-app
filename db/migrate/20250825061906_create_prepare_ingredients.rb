class CreatePrepareIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :prepare_ingredients do |t|
      t.references :prepare, null: false, foreign_key: true
      t.string :ingredient_name, null: false
      t.boolean :checked, default: false

      t.timestamps
    end

    add_index :prepare_ingredients, [ :prepare_id, :ingredient_name ]
  end
end
