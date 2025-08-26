class AddCounterCachesToPrepares < ActiveRecord::Migration[8.0]
  def up
    add_column :prepares, :prepare_ingredients_count, :integer, default: 0
    add_column :prepares, :checked_ingredients_count, :integer, default: 0

    # Populate existing counter cache values
    Prepare.find_each do |prepare|
      prepare.update_columns(
        prepare_ingredients_count: prepare.prepare_ingredients.count,
        checked_ingredients_count: prepare.prepare_ingredients.checked.count
      )
    end
  end

  def down
    remove_column :prepares, :prepare_ingredients_count
    remove_column :prepares, :checked_ingredients_count
  end
end
