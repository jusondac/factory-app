class PrepareQuery
  include ActiveModel::Model
  
  attr_accessor :params

  def initialize(params = {})
    @params = params || {}
  end

  def call
    Prepare.includes(
      unit_batch: :product,
      created_by: [],
      checked_by: [],
      prepare_ingredients: []
    ).ransack(ransack_params)
  end

  def auto_cancel_outdated_prepares_batch(prepares)
    # Find all preparations that should be cancelled in a single query
    outdated_ids = prepares.select { |p| p.prepare_date < Date.current && (p.unchecked? || p.checking?) }
                          .map(&:id)
    
    # Batch update all outdated preparations in a single query
    if outdated_ids.any?
      Prepare.where(id: outdated_ids).update_all(status: :cancelled, checked_by_id: nil)
      
      # Update the in-memory objects to reflect the changes
      prepares.each do |prepare|
        if outdated_ids.include?(prepare.id)
          prepare.status = 'cancelled'
          prepare.checked_by = nil
        end
      end
    end
  end

  private

  def ransack_params
    @params[:q] || {}
  end
end
