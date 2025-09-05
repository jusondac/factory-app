WickedPdf.config = {
  # Path to the wkhtmltopdf executable
  exe_path: '/usr/local/bin/wkhtmltopdf',
  
  # Enable local file access
  enable_local_file_access: true,
  
  # Default options for PDF generation
  page_size: 'A4',
  margin: {
    top: 20,
    bottom: 20,
    left: 20,
    right: 20
  },
  orientation: 'Landscape',
  
  # Encoding settings
  encoding: 'UTF-8',
  
  # Print media type for better styling
  print_media_type: true,
  
  # Disable smart shrinking
  disable_smart_shrinking: true,
  
  # Image quality
  image_quality: 94
}
