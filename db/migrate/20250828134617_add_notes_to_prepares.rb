class AddNotesToPrepares < ActiveRecord::Migration[8.0]
  def change
    add_column :prepares, :notes, :string
  end
end
