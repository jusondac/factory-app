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
        @report_data = ReportService.core_process_report(@start_date, @end_date)
        prepare_machine_data(@report_data) if @report_data
        @report_data
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

  def prepare_machine_data(report_data)
    # Collect only production machines and their checking questions
    @production_machines = []
    @production_machine_checkings = []

    report_data.values.flatten.each do |unit_batch|
      # Only collect machines used in production (produce process)
      if unit_batch.produce&.machine
        unless @production_machines.any? { |m| m.id == unit_batch.produce.machine.id }
          @production_machines << unit_batch.produce.machine
          unit_batch.produce.machine.machine_checkings.each do |checking|
            @production_machine_checkings << checking unless @production_machine_checkings.any? { |c| c.id == checking.id }
          end
        end
      end
    end

    # Group checkings by production machine
    @production_machine_checkings_grouped = @production_machines.map do |machine|
      {
        machine: machine,
        checkings: machine.machine_checkings
      }
    end
  end

  # No additional private methods needed - WickedPDF uses the HTML template
end
