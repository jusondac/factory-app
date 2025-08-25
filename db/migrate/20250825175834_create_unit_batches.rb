class CreateUnitBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :unit_batches do |t|
      t.string :unit_id
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
