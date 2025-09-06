class ReportService
  def self.clear_cache
    Rails.cache.delete_matched("report_*")
  end

  # Helper method to ensure consistent timezone conversion
  def self.to_local_date(datetime)
    return nil unless datetime
    datetime.in_time_zone.to_date
  end

  def self.unit_batch_report(start_date = nil, end_date = nil)
    cache_key = "report_unit_batch_#{start_date}_#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      query = UnitBatch.joins(:prepare).includes(:product, :prepare, :produce, :package)
      query = query.where(prepares: { prepare_date: start_date..end_date }) if start_date && end_date
      query.order("prepares.prepare_date DESC").group_by { |ub| ub.prepare.prepare_date }
    end
  end

  def self.core_process_report(start_date = nil, end_date = nil)
      query = UnitBatch.joins(:prepare).left_joins(:produce, :package).includes(
        :product,
        prepare: [ :prepare_ingredients ],
        produce: [ :machine, produce_machine_checks: [ :machine_checking ] ],
        package: [ :machine, package_machine_checks: [ :machine_checking ] ]
      )

      if start_date && end_date
        # Filter by date range using multiple conditions for different date fields
        date_conditions = [
          "prepares.prepare_date BETWEEN ? AND ?",
          "produces.product_date BETWEEN ? AND ?",
          "date(unit_batches.created_at) BETWEEN ? AND ?"
        ].join(" OR ")

        query = query.where(date_conditions, start_date, end_date, start_date, end_date, start_date, end_date)
      end

      query = query.order("prepares.prepare_date DESC, produces.product_date DESC, unit_batches.created_at DESC")

      # Group by the most relevant date for display (converted to local timezone)
      query.group_by do |unit_batch|
        # Use the most recent relevant date for grouping
        dates = [
          unit_batch.produce&.product_date,
          unit_batch.prepare&.prepare_date,
          to_local_date(unit_batch.created_at)
        ].compact

        # Return the most recent date that falls within our range (if specified)
        if start_date && end_date
          dates.find { |date| date >= start_date && date <= end_date } || dates.first
        else
          dates.first
        end
      end
  end

  def self.ingredients_product_machine_report(start_date = nil, end_date = nil)
    cache_key = "report_ingredients_product_machine_#{start_date}_#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      query = UnitBatch.joins(:prepare).includes(
        :product,
        prepare: [ :prepare_ingredients ],
        produce: [ :machine ],
        package: [ :machine ]
      )
      query = query.where(prepares: { prepare_date: start_date..end_date }) if start_date && end_date
      query.order("prepares.prepare_date DESC").group_by { |ub| ub.prepare.prepare_date }
    end
  end

  def self.all_report(start_date = nil, end_date = nil)
    cache_key = "report_all_#{start_date}_#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      query = UnitBatch.joins(:prepare).includes(:product, :prepare, :produce, :package)
      query = query.where(prepares: { prepare_date: start_date..end_date }) if start_date && end_date
      query.order("prepares.prepare_date DESC").group_by { |ub| ub.prepare.prepare_date }
    end
  end

  def self.core_report(start_date = nil, end_date = nil)
    cache_key = "report_core_#{start_date}_#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 1.minute) do
      query = UnitBatch.joins(:prepare, :produce, :package).includes(:product, :prepare, :produce, :package)
      query = query.where(prepares: { prepare_date: start_date..end_date }) if start_date && end_date
      query.order("prepares.prepare_date DESC").group_by { |ub| ub.prepare.prepare_date }
    end
  end

  def self.min_date
    Rails.cache.fetch("min_prepare_date", expires_in: 1.day) do
      Prepare.minimum(:prepare_date)
    end
  end
end
