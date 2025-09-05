class ReportsController < ApplicationController
  def index
    @min_date = ReportService.min_date
    @report_type = params[:report_type]
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date

    # Only show data if filters have been submitted
    if @report_type.present? && @start_date.present? && @end_date.present?
      @show_data = true
      @report_data = case @report_type
      when "unit_batch"
        ReportService.unit_batch_report(@start_date, @end_date)
      when "core_process"
        ReportService.core_process_report(@start_date, @end_date)
      when "ingredients_product_machine"
        ReportService.ingredients_product_machine_report(@start_date, @end_date)
      end
    else
      @show_data = false
    end

    respond_to do |format|
      format.html
      format.pdf do
        if @show_data
          render pdf: "#{@report_type}_report_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}"
        else
          redirect_to reports_path, alert: "Please select filters first"
        end
      end
    end
  end

  private

  # No additional private methods needed - WickedPDF uses the HTML template
end
