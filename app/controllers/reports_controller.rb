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
          pdf_data = generate_pdf_report(@report_data, @report_type, @start_date, @end_date)

          send_data pdf_data,
                   filename: "#{@report_type}_report_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}.pdf",
                   type: 'application/pdf',
                   disposition: 'attachment'
        rescue => e
          Rails.logger.error "PDF generation failed: #{e.message}"
          redirect_to reports_path, alert: "PDF generation failed: #{e.message}"
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

  private

  def generate_pdf_report(report_data, report_type, start_date, end_date)
    require 'prawn'
    require 'prawn/table'

    Prawn::Document.new(page_size: 'A4', page_layout: :landscape, margin: [20, 20, 20, 20]) do |pdf|
      # Header
      pdf.font_size 20
      pdf.text "#{report_type&.humanize || 'Report'} Report", align: :center, style: :bold
      pdf.move_down 10

      pdf.font_size 12
      pdf.text "Generated on: #{Time.current.strftime('%B %d, %Y at %I:%M %p')}", align: :center
      pdf.text "Report Period: #{start_date&.strftime('%b %d, %Y') || 'N/A'} - #{end_date&.strftime('%b %d, %Y') || 'N/A'}", align: :center
      pdf.move_down 20

      # Summary
      report_data ||= {}
      all_batches = report_data.values&.flatten || []
      total_batches = all_batches.count
      completed_batches = all_batches.select { |ub| ub&.status == 'packing' }.count
      in_progress_batches = all_batches.select { |ub| ['preparation', 'production'].include?(ub&.status) }.count
      cancelled_batches = all_batches.select { |ub| ub&.status == 'cancelled' }.count

      pdf.font_size 14
      pdf.text "Summary", style: :bold
      pdf.move_down 10

      summary_data = [
        ['Total Batches', total_batches.to_s],
        ['Completed', completed_batches.to_s],
        ['In Progress', in_progress_batches.to_s],
        ['Cancelled', cancelled_batches.to_s]
      ]

      pdf.table(summary_data, width: pdf.bounds.width) do |table|
        table.column(0).font_style = :bold
        table.column(0).background_color = 'f0f0f0'
        table.column(1).align = :center
        table.cells.padding = 8
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.5
      end

      pdf.move_down 20

      # Report Data
      pdf.font_size 14
      pdf.text "Report Data", style: :bold
      pdf.move_down 10

      if report_data.present? && report_data.any?
        report_data.each do |date, unit_batches|
          next unless unit_batches.is_a?(Array) && unit_batches.any?

          # Date header
          pdf.font_size 12
          batch_count = unit_batches.count
          pdf.text "#{date&.strftime('%B %d, %Y') || 'Unknown Date'} (#{batch_count} batch#{batch_count != 1 ? 'es' : ''})",
                   style: :bold, color: '0066cc'
          pdf.move_down 5

          if report_type == 'core'
            # Core Process Report - Simplified view
            table_data = [['Batch Code', 'Product', 'Produce Machine', 'Package Machine', 'Unchecked Ingredients']]

            unit_batches.each do |unit_batch|
              next unless unit_batch

              # Get produce machine
              produce_machine = unit_batch.produce&.machine&.name || 'N/A'

              # Get package machine
              package_machine = unit_batch.package&.machine&.name || 'N/A'

              # Get unchecked ingredients
              unchecked_ingredients = []
              if unit_batch.prepare&.prepare_ingredients
                unit_batch.prepare.prepare_ingredients.each do |prep_ing|
                  if prep_ing.status != 'checked'
                    unchecked_ingredients << (prep_ing.ingredient&.name || 'Unknown Ingredient')
                  end
                end
              end
              unchecked_text = unchecked_ingredients.any? ? unchecked_ingredients.join(', ') : 'All checked'

              table_data << [
                unit_batch.batch_code || 'N/A',
                unit_batch.product&.name || 'No product',
                produce_machine,
                package_machine,
                unchecked_text
              ]
            end
          else
            # All Unit Batches Report - Full view
            table_data = [['Unit ID', 'Batch Code', 'Product', 'Status', 'Processes', 'Quantity', 'Date']]

            unit_batches.each do |unit_batch|
              next unless unit_batch

              processes = []
              processes << 'Prepare' if unit_batch.prepare
              processes << 'Produce' if unit_batch.produce
              processes << 'Package' if unit_batch.package
              processes_text = processes.join(', ')

              table_data << [
                unit_batch.unit_id || 'N/A',
                unit_batch.batch_code || 'N/A',
                unit_batch.product&.name || 'No product',
                unit_batch.status&.humanize || 'Unknown',
                processes_text.presence || 'None',
                unit_batch.quantity&.to_s || '0',
                date&.strftime('%b %d, %Y') || 'N/A'
              ]
            end
          end

          if table_data.length > 1
            begin
              # Ensure all data is properly formatted as strings
              clean_table_data = table_data.map do |row|
                row.map { |cell| cell.to_s }
              end

              pdf.table(clean_table_data, width: pdf.bounds.width, header: true) do |table|
                table.row(0).font_style = :bold
                table.row(0).background_color = 'e0e0e0'
                table.cells.padding = [4, 6, 4, 6] # top, right, bottom, left
                table.cells.borders = [:all]
                table.cells.border_width = 0.5
                table.cells.size = 8
                table.cells.overflow = :truncate
              end
            rescue => e
              pdf.text "Error generating table for #{date&.strftime('%B %d, %Y')}: #{e.message}", color: 'ff0000'
              pdf.text "Debug info: table_data length = #{table_data.length}", color: '666666', size: 8
            end
          end

          pdf.move_down 15
        end
      else
        pdf.text "No data found for the selected criteria.", color: '666666'
      end

      # Footer
      pdf.move_down 20
      pdf.font_size 8
      pdf.text "Report generated by Factory Management System", align: :center, color: '666666'
      pdf.text "© #{Time.current.year} All rights reserved", align: :center, color: '666666'
    end.render
  end
end
