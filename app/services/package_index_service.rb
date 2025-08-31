class PackageIndexService
  CACHE_EXPIRY = 15.minutes

  def initialize(params = {})
    @params = params
    @search_params = params[:q] || {}
    @page = params[:page] || 1
    @per_page = params[:per_page] || 10
    @tab = params[:tab] || "today"
  end

  def call
    {
      packages: packages,
      search: search_object,
      total_count: total_count,
      current_page: @page.to_i,
      total_pages: total_pages
    }
  end

  private

  def packages
    @packages ||= if search_params_present?
      # Don't cache search results - return paginated collection
      search_and_paginate
    else
      # Return paginated collection even when using cache
      paginated_packages
    end
  end

  def search_object
    @search ||= Package.ransack(@search_params)
  end

  def search_and_paginate
    base_query = apply_tab_filter(search_object.result)
    base_query.with_includes
              .page(@page)
              .per(@per_page)
              .order(created_at: :desc)
  end

  def paginated_packages
    # Always return paginated collection for consistency
    base_query = apply_tab_filter(Package)
    base_query.with_includes
              .page(@page)
              .per(@per_page)
              .order(created_at: :desc)
  end

  def total_count
    @total_count ||= if search_params_present?
      apply_tab_filter(search_object.result).count
    else
      Rails.cache.fetch("#{base_cache_key}_count_#{@tab}", expires_in: CACHE_EXPIRY) do
        apply_tab_filter(Package).count
      end
    end
  end

  def total_pages
    (total_count.to_f / @per_page).ceil
  end

  def search_params_present?
    @search_params.present? && @search_params.values.any?(&:present?)
  end

  def apply_tab_filter(query)
    case @tab
    when "today"
      query.today
    when "history"
      query.history
    else
      query
    end
  end

  def base_cache_key
    "packages_index_page_#{@page}_per_#{@per_page}_tab_#{@tab}"
  end
end
