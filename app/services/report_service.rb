class ReportService
  def self.clear_cache
    Rails.cache.delete_matched("report_*")
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
    cache_key = "report_core_process_#{start_date}_#{end_date}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      query = UnitBatch.joins(:prepare).left_joins(:produce, :package).includes(
        :product,
        prepare: [ :prepare_ingredients ],
        produce: [ :machine, produce_machine_checks: [ :machine_checking ] ],
        package: [ :machine, package_machine_checks: [ :machine_checking ] ]
      )

      if start_date && end_date
        # Include batches that have prepare_date OR product_date in the range
        query = query.where(
          "(prepares.prepare_date BETWEEN ? AND ?) OR (produces.product_date BETWEEN ? AND ?) OR (unit_batches.created_at::date BETWEEN ? AND ?)",
          start_date, end_date, start_date, end_date, start_date, end_date
        )
      end

      # Order by the most recent relevant date
      query = query.order("GREATEST(COALESCE(produces.product_date, '1900-01-01'), COALESCE(prepares.prepare_date, '1900-01-01'), unit_batches.created_at::date) DESC")

      # Group by the most relevant date for display
      query.group_by do |ub|
        if ub.produce&.product_date && (start_date.nil? || ub.produce.product_date >= start_date)
          ub.produce.product_date
        elsif ub.prepare&.prepare_date
          ub.prepare.prepare_date
        else
          ub.created_at.to_date
        end
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
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
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
