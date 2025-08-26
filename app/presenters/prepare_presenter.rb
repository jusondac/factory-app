class PreparePresenter
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TagHelper

  attr_reader :prepare

  def initialize(prepare)
    @prepare = prepare
  end

  def status_badge_class
    case prepare.status
    when 'unchecked'
      'bg-yellow-100 text-yellow-800'
    when 'checking'
      'bg-blue-100 text-blue-800'
    when 'checked'
      'bg-green-100 text-green-800'
    when 'cancelled'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def progress_bar_class
    prepare.checked? ? 'bg-green-500' : 'bg-blue-500'
  end

  def formatted_date
    prepare.prepare_date.strftime("%B %d, %Y")
  end

  def short_formatted_date
    prepare.prepare_date.strftime("%m/%d/%Y")
  end

  def created_by_info
    return "Unknown" unless prepare.created_by
    "#{prepare.created_by.email_address} (#{prepare.created_by.role.humanize})"
  end

  def checked_by_info
    return nil unless prepare.checked_by
    "#{prepare.checked_by.email_address} (#{prepare.checked_by.role.humanize})"
  end

  def product_name
    prepare.product&.name || "Unknown Product"
  end

  def is_clickable?
    prepare.clickable?
  end

  def row_classes
    base_classes = "hover:bg-gray-50 transition-colors duration-150"
    clickable_classes = is_clickable? ? "cursor-pointer" : "cursor-not-allowed opacity-60"
    "#{base_classes} #{clickable_classes}"
  end

  def can_show_progress?
    @can_show_progress ||= prepare.prepare_ingredients.any? && !prepare.cancelled?
  end

  def progress_percentage
    @progress_percentage ||= prepare.checking_percentage
  end

  def progress_text
    @progress_text ||= prepare.checking_progress
  end
end
