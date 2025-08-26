module UnitBatchesHelper
  def status_badge_class(status)
    case status
    when "preparation"
      "bg-yellow-100 text-yellow-800"
    when "production"
      "bg-blue-100 text-blue-800"
    when "testing"
      "bg-orange-100 text-orange-800"
    when "packing"
      "bg-green-100 text-green-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def status_icon_svg
    '<svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
      <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>'.html_safe
  end

  def unit_batch_progress_percentage(unit_batch)
    case unit_batch.status
    when "preparation"
      25
    when "production"
      50
    when "testing"
      75
    when "packing"
      100
    else
      0
    end
  end

  def unit_batch_next_status(current_status)
    case current_status
    when "preparation"
      "production"
    when "production"
      "testing"
    when "testing"
      "packing"
    else
      nil
    end
  end
end
