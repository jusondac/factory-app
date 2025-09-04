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
          pdf_data = generate_pdf_report(@report_data, @report_type, @start_date, @end_date)
          send_data pdf_data,
                   filename: "#{@report_type}_report_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}.pdf",
                   type: "application/pdf",
                   disposition: "attachment"
        else
          redirect_to reports_path, alert: "Please select filters first"
        end
      end
    end
  end

  private

  def sanitize_text_for_pdf(text)
    return "" if text.nil?

    # Convert to string and ensure UTF-8 encoding
    text = text.to_s.force_encoding("UTF-8")

    # Replace problematic UTF-8 characters with ASCII equivalents
    replacements = {
      "\u2713" => "[Y]",  # checkmark
      "\u2717" => "[N]",  # cross mark
      "\u2013" => "-",    # en dash
      "\u2014" => "--",   # em dash
      "\u2018" => "'",    # left single quote
      "\u2019" => "'",    # right single quote
      "\u201C" => '"',    # left double quote
      "\u201D" => '"',    # right double quote
      "\u2026" => "..."   # ellipsis
    }

    replacements.each { |utf8_char, ascii_char| text.gsub!(utf8_char, ascii_char) }

    # Try to encode to Windows-1252, fall back to ASCII if that fails
    begin
      text.encode("Windows-1252",
                  invalid: :replace,
                  undef: :replace,
                  replace: "?")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      # Fallback to ASCII if Windows-1252 encoding fails
      text.encode("ASCII",
                  invalid: :replace,
                  undef: :replace,
                  replace: "?")
    end
  rescue => e
    # Ultimate fallback
    Rails.logger.warn "PDF text sanitization failed: #{e.message}"
    text.to_s.gsub(/[^\x00-\x7F]/, "?") # Replace all non-ASCII with ?
  end

  def generate_pdf_report(report_data, report_type, start_date, end_date)
    require "prawn"
    require "prawn/table"

    # Hide the UTF-8 warning since we handle character encoding properly
    Prawn::Fonts::AFM.hide_m17n_warning = true

    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: [ 20, 20, 20, 20 ]) do |pdf|
      # Use a font that supports UTF-8 characters
      pdf.font "Helvetica"
      # Header
      pdf.font_size 20
      pdf.text sanitize_text_for_pdf("#{report_type&.humanize || 'Report'} Report"), align: :center, style: :bold
      pdf.move_down 10

      pdf.font_size 12
      pdf.text sanitize_text_for_pdf("Generated on: #{Time.current.strftime('%B %d, %Y at %I:%M %p')}"), align: :center
      pdf.text sanitize_text_for_pdf("Report Period: #{start_date&.strftime('%b %d, %Y') || 'N/A'} - #{end_date&.strftime('%b %d, %Y') || 'N/A'}"), align: :center
      pdf.move_down 20

      # Summary
      report_data ||= {}
      all_batches = report_data.values&.flatten || []
      total_batches = all_batches.count
      completed_batches = all_batches.select { |ub| ub&.status == "packing" }.count
      in_progress_batches = all_batches.select { |ub| [ "preparation", "production" ].include?(ub&.status) }.count
      cancelled_batches = all_batches.select { |ub| ub&.status == "cancelled" }.count

      pdf.font_size 14
      pdf.text "Summary", style: :bold
      pdf.move_down 10

      summary_data = [
        [ "Total Batches", total_batches.to_s ],
        [ "Completed", completed_batches.to_s ],
        [ "In Progress", in_progress_batches.to_s ],
        [ "Cancelled", cancelled_batches.to_s ]
      ]

      pdf.table(summary_data, width: pdf.bounds.width) do |table|
        table.column(0).font_style = :bold
        table.column(0).background_color = "f0f0f0"
        table.column(1).align = :center
        table.cells.padding = 8
        table.cells.borders = [ :bottom ]
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
          pdf.text sanitize_text_for_pdf("#{date&.strftime('%B %d, %Y') || 'Unknown Date'} (#{batch_count} batch#{batch_count != 1 ? 'es' : ''})"),
                   style: :bold, color: "0066cc"
          pdf.move_down 5

          case report_type
          when "core_process"
            # Core Process Report
            table_data = [ [ "Batch Code", "Product", "Machine", "Ingredients Checked", "Unchecked Ingredients", "Machine Checks" ] ]

            unit_batches.each do |unit_batch|
              next unless unit_batch

              # Get machine info
              machine_info = []
              machine_info << sanitize_text_for_pdf("Produce: #{unit_batch.produce&.machine&.name || 'N/A'}") if unit_batch.produce
              machine_info << sanitize_text_for_pdf("Package: #{unit_batch.package&.machine&.name || 'N/A'}") if unit_batch.package
              machine_text = machine_info.join(", ")

              # Get ingredients info
              total_ingredients = 0
              checked_count = 0
              unchecked_ingredients = []

                if unit_batch.prepare&.prepare_ingredients
                  total_ingredients = unit_batch.prepare.prepare_ingredients.count
                  checked_count = unit_batch.prepare.prepare_ingredients.select { |prep_ing| prep_ing.checked }.count
                  unit_batch.prepare.prepare_ingredients.each do |prep_ing|
                    if !prep_ing.checked
                      unchecked_ingredients << sanitize_text_for_pdf(prep_ing.ingredient_name || "Unknown Ingredient")
                    end
                  end
                end

              ingredients_text = "#{checked_count}/#{total_ingredients}"
              unchecked_text = unchecked_ingredients.any? ? unchecked_ingredients.join(", ") : "All checked"

              # Get machine checks
              machine_checks = []
              if unit_batch.produce&.produce_machine_checks
                machine_checks << "Produce: #{unit_batch.produce.produce_machine_checks.count} checks"
              end
              if unit_batch.package&.package_machine_checks
                machine_checks << "Package: #{unit_batch.package.package_machine_checks.count} checks"
              end
              machine_checks_text = machine_checks.any? ? machine_checks.join(", ") : "No checks"

              table_data << [
                unit_batch.batch_code || "N/A",
                unit_batch.product&.name || "No product",
                machine_text,
                ingredients_text,
                unchecked_text,
                machine_checks_text
              ]
            end
          when "ingredients_product_machine"
            # Ingredients-Product-Machine Report
            table_data = [ [ "Batch Code", "Product", "Ingredients", "Machines", "Status" ] ]

            unit_batches.each do |unit_batch|
              next unless unit_batch

              # Get ingredients list
              ingredients_list = []
              if unit_batch.prepare&.prepare_ingredients
                unit_batch.prepare.prepare_ingredients.each do |prep_ing|
                  status = prep_ing.checked ? "[Y]" : "[N]"
                  ingredient_name = sanitize_text_for_pdf(prep_ing.ingredient_name)
                  ingredients_list << "#{ingredient_name} (#{status})"
                end
              end
              ingredients_text = ingredients_list.any? ? ingredients_list.join(", ") : "No ingredients"

              # Get machines
              machines = []
              machines << sanitize_text_for_pdf("Produce: #{unit_batch.produce&.machine&.name || 'N/A'}") if unit_batch.produce
              machines << sanitize_text_for_pdf("Package: #{unit_batch.package&.machine&.name || 'N/A'}") if unit_batch.package
              machines_text = machines.any? ? machines.join(", ") : "No machines"

              table_data << [
                unit_batch.batch_code || "N/A",
                unit_batch.product&.name || "No product",
                ingredients_text,
                machines_text,
                unit_batch.status&.humanize || "Unknown"
              ]
            end
          else
            # Unit Batch Report - Default view
            table_data = [ [ "Unit ID", "Batch Code", "Product", "Status", "Processes", "Quantity", "Date" ] ]

            unit_batches.each do |unit_batch|
              next unless unit_batch

              processes = []
              processes << "Prepare" if unit_batch.prepare
              processes << "Produce" if unit_batch.produce
              processes << "Package" if unit_batch.package
              processes_text = processes.join(", ")

              table_data << [
                unit_batch.unit_id || "N/A",
                unit_batch.batch_code || "N/A",
                unit_batch.product&.name || "No product",
                unit_batch.status&.humanize || "Unknown",
                processes_text.presence || "None",
                unit_batch.quantity&.to_s || "0",
                date&.strftime("%b %d, %Y") || "N/A"
              ]
            end
          end

          if table_data.length > 1
            begin
              # Ensure all data is properly formatted as strings and sanitized for PDF
              clean_table_data = table_data.map do |row|
                row.map { |cell| sanitize_text_for_pdf(cell.to_s) }
              end

              pdf.table(clean_table_data, width: pdf.bounds.width, header: true) do |table|
                table.row(0).font_style = :bold
                table.row(0).background_color = "e0e0e0"
                table.cells.padding = [ 4, 6, 4, 6 ] # top, right, bottom, left
                table.cells.borders = [ :all ]
                table.cells.border_width = 0.5
                table.cells.size = 8
                table.cells.overflow = :truncate
              end
            rescue => e
              pdf.text sanitize_text_for_pdf("Error generating table for #{date&.strftime('%B %d, %Y')}: #{e.message}"), color: "ff0000"
              pdf.text sanitize_text_for_pdf("Debug info: table_data length = #{table_data.length}"), color: "666666", size: 8
            end
          end

          pdf.move_down 15
        end
      else
        pdf.text sanitize_text_for_pdf("No data found for the selected criteria."), color: "666666"
      end

      # Footer
      pdf.move_down 20
      pdf.font_size 8
      pdf.text sanitize_text_for_pdf("Report generated by Factory Management System"), align: :center, color: "666666"
      pdf.text sanitize_text_for_pdf("© #{Time.current.year} All rights reserved"), align: :center, color: "666666"
    end.render
  end
end
