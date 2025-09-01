class ReportsController < ApplicationController
  def index
    @min_date = ReportService.min_date
    @report_type = params[:report_type] || 'all'
    @start_date = params[:start_date]&.to_date || @min_date
    @end_date = params[:end_date]&.to_date || Date.current

    respond_to do |format|
      format.html do
        @report_data = case @report_type
        when 'all'
          ReportService.all_report(@start_date, @end_date)
        when 'core'
          ReportService.core_report(@start_date, @end_date)
        end
      end
      format.pdf do
        @report_data = case @report_type
        when 'all'
          ReportService.all_report(@start_date, @end_date)
        when 'core'
          ReportService.core_report(@start_date, @end_date)
        end

        begin
          pdf = WickedPdf.new.pdf_from_string(
            render_to_string(template: 'reports/index.pdf.erb', layout: false),
            page_size: 'A4',
            orientation: 'Landscape',
            margin: { top: 10, bottom: 10, left: 10, right: 10 }
          )

          send_data pdf,
                   filename: "#{@report_type}_report_#{@start_date}_to_#{@end_date}.pdf",
                   type: 'application/pdf',
                   disposition: 'attachment'
        rescue => e
          Rails.logger.error "PDF generation failed: #{e.message}"
          redirect_to reports_path, alert: "PDF generation failed. Please ensure wkhtmltopdf is properly installed."
        end
      end
    end
  end

  def all
    @min_date = ReportService.min_date
    start_date = params[:start_date]&.to_date || @min_date
    end_date = params[:end_date]&.to_date || Date.current
    @report_data = ReportService.all_report(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def core
    @min_date = ReportService.min_date
    start_date = params[:start_date]&.to_date || @min_date
    end_date = params[:end_date]&.to_date || Date.current
    @report_data = ReportService.core_report(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end
end
