# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for all WickedPDF requests.

WickedPdf.configure do |config|
  # Use the wkhtmltopdf binary from the wkhtmltopdf-binary gem
  # Found at: /home/rejka/.rvm/gems/ruby-3.2.1/bin/wkhtmltopdf
  config.exe_path = '/home/rejka/.rvm/gems/ruby-3.2.1/bin/wkhtmltopdf'

  # Additional command line options for better PDF generation
  # config.wkhtmltopdf = '--disable-smart-shrinking --print-media-type --no-background'
end Configuration
#
# Use this to set up shared configuration options for all WickedPDF requests.
# Many of these configs can be overridden in the 'render :pdf' call.
#
# Using wkhtmltopdf-binary gem for wkhtmltopdf executable

WickedPdf.configure do |config|
  # Use the wkhtmltopdf binary from the wkhtmltopdf-binary gem
  config.exe_path = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')

  # Alternative approach if the above doesn't work
  # config.exe_path = `which wkhtmltopdf`.strip
  # config.exe_path = `bundle exec which wkhtmltopdf`.strip if config.exe_path.empty?

  # Additional command line options for better PDF generation
  # config.wkhtmltopdf = '--disable-smart-shrinking --print-media-type --no-background'
end
