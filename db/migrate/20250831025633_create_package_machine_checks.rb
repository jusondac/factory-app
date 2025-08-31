class CreatePackageMachineChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :package_machine_checks do |t|
      t.references :package, null: false, foreign_key: true
      t.references :machine_checking, null: false, foreign_key: true
      t.string :question
      t.text :answer

      t.timestamps
    end
  end
end
