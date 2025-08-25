class AddUnitBatchToPrepareAndRemoveProduct < ActiveRecord::Migration[8.0]
  def up
    # First, add unit_batch reference as nullable
    add_reference :prepares, :unit_batch, null: true, foreign_key: true

    # Create UnitBatch records for existing Prepare records using raw SQL
    execute <<-SQL
      INSERT INTO unit_batches (product_id, unit_id, created_at, updated_at)
      SELECT#{' '}
        p.product_id,
        COALESCE(p.prepare_id, 'UNIT-' || strftime('%Y%m%d', p.prepare_date) || '-' || p.id) as unit_id,
        datetime('now') as created_at,
        datetime('now') as updated_at
      FROM prepares p;
    SQL

    # Update prepares to reference the new unit_batches
    execute <<-SQL
      UPDATE prepares#{' '}
      SET unit_batch_id = (
        SELECT ub.id#{' '}
        FROM unit_batches ub#{' '}
        WHERE ub.product_id = prepares.product_id#{' '}
        AND ub.unit_id = COALESCE(prepares.prepare_id, 'UNIT-' || strftime('%Y%m%d', prepares.prepare_date) || '-' || prepares.id)
        LIMIT 1
      );
    SQL

    # Now make unit_batch_id not nullable
    change_column_null :prepares, :unit_batch_id, false

    # Remove the unique index on product_id and prepare_date first
    remove_index :prepares, [ :product_id, :prepare_date ]

    # Remove product reference from prepares table
    remove_reference :prepares, :product, null: false, foreign_key: true

    # The unit_batch_id already has a regular index from the foreign key reference
    # We'll add uniqueness constraint at the model level instead of database level
  end

  def down
    # Add product reference back
    add_reference :prepares, :product, null: true, foreign_key: true

    # Restore product references from unit_batch using raw SQL
    execute <<-SQL
      UPDATE prepares#{' '}
      SET product_id = (
        SELECT ub.product_id#{' '}
        FROM unit_batches ub#{' '}
        WHERE ub.id = prepares.unit_batch_id
      );
    SQL

    # Make product_id not nullable
    change_column_null :prepares, :product_id, false

    # Add back the unique index on product_id and prepare_date
    add_index :prepares, [ :product_id, :prepare_date ], unique: true

    # Remove unit_batch reference
    remove_reference :prepares, :unit_batch, null: false, foreign_key: true

    # Clean up unit_batches that were created for this migration
    execute "DELETE FROM unit_batches;"
  end
end
