class CreatePackages < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:packages)
      create_table :packages do |t|
        t.date :package_date, null: false
        t.string :package_id, null: false
        t.integer :status, default: 0, null: false
        t.references :unit_batch, null: false, foreign_key: true
        t.references :machine, null: true, foreign_key: true
        t.integer :waste_quantity, default: 0

        t.timestamps
      end
    end

    add_index :packages, :package_id, unique: true unless index_exists?(:packages, :package_id)
    add_index :packages, :package_date unless index_exists?(:packages, :package_date)
    add_index :packages, :unit_batch_id, unique: true unless index_exists?(:packages, :unit_batch_id)
  end
end
