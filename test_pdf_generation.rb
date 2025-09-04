#!/usr/bin/env ruby

require_relative 'config/environment'
require 'ostruct'

# Test PDF generation with problematic characters
puts "Testing PDF generation with UTF-8 characters..."

# Create test data with potentially problematic characters
test_data = {
  Date.today => [
    OpenStruct.new(
      batch_code: "TEST-001",
      product: OpenStruct.new(name: "Café au lait with émojis ✓"),
      status: "completed",
      quantity: 100,
      unit_id: "UNIT-001",
      prepare: OpenStruct.new(
        prepare_ingredients: [
          OpenStruct.new(ingredient_name: "Sugar ✓", checked: true),
          OpenStruct.new(ingredient_name: "Milk — organic", checked: false),
          OpenStruct.new(ingredient_name: "Coffee ☕", checked: true)
        ]
      ),
      produce: OpenStruct.new(
        machine: OpenStruct.new(name: "Machine — Pro"),
        produce_machine_checks: []
      ),
      package: OpenStruct.new(
        machine: OpenStruct.new(name: "Packager 'Deluxe'"),
        package_machine_checks: []
      )
    )
  ]
}

begin
  # Test the reports controller method
  controller = ReportsController.new
  pdf_data = controller.send(:generate_pdf_report, test_data, 'core_process', Date.today, Date.today)

  # Save test PDF
  File.open('test_pdf_output.pdf', 'wb') do |file|
    file.write(pdf_data)
  end
  puts "✅ PDF generated successfully! Saved as test_pdf_output.pdf"
  puts "File size: #{File.size('test_pdf_output.pdf')} bytes"

rescue => e
  puts "❌ PDF generation failed: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(10).join("\n")
end
