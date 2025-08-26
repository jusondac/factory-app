class MachineChecking < ApplicationRecord
  belongs_to :machine

  validates :checking_name, presence: true
  validates :checking_type, presence: true
  validates :checking_value, presence: true, if: -> { checking_type == "option" }

  enum :checking_type, { option: 0, text: 1 }

  def checking_options
    return [] unless checking_type == "option" && checking_value.present?
    checking_value.split(',').map(&:strip)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["checking_name", "checking_type", "checking_value", "created_at", "id", "id_value", "machine_id", "updated_at"]
  end
end
