class ProduceMachineSelectionService
  include ActiveModel::Model

  attr_accessor :produce, :user, :machine_id

  validates :produce, presence: true
  validates :user, presence: true
  validates :machine_id, presence: true

  def initialize(attributes = {})
    super
  end

  def select_machine
    return { success: false, alert: "Machine checking has already been completed." } if produce.machine_check?

    machine = Machine.find_by(id: machine_id)
    return { success: false, alert: "Selected machine not found." } unless machine
    return { success: false, alert: "Selected machine is not allocated for production." } unless machine.production?
    return { success: false, alert: "Selected machine is currently in use." } unless machine.inactive?

    ActiveRecord::Base.transaction do
      # Clear any existing machine checks if changing machine
      if produce.machine.present? && produce.machine != machine
        produce.produce_machine_checks.destroy_all
      end

      # Activate the machine when it's selected for production
      machine.update!(status: :active)
      produce.update!(machine: machine)

      { success: true, notice: "Machine selected and activated successfully." }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, alert: "Error selecting machine: #{e.message}" }
  rescue StandardError => e
    { success: false, alert: "An unexpected error occurred: #{e.message}" }
  end
end
