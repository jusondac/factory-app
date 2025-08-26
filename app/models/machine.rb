class Machine < ApplicationRecord
  has_many :machine_checkings, dependent: :destroy
  accepts_nested_attributes_for :machine_checkings, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :serial_number, presence: true, uniqueness: true

  enum :status, { inactive: 0, active: 1, under_maintenance: 2 }, default: :inactive

  before_validation :generate_serial_number, on: :create

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "serial_number", "status", "updated_at"]
  end

  private

  def generate_serial_number
    return if serial_number.present?
    
    loop do
      self.serial_number = SecureRandom.hex(5).upcase
      break unless Machine.exists?(serial_number: serial_number)
    end
  end
end
