class PackageMachineSelectionService
  include ActiveModel::Model

  attr_accessor :package, :user, :machine_id

  validates :package, presence: true
  validates :user, presence: true
  validates :machine_id, presence: true

  def initialize(attributes = {})
    super
  end

  def select_machine
    return { success: false, alert: "Machine checking has already been completed." } if package.machine_check?

    machine = Machine.find_by(id: machine_id)
    return { success: false, alert: "Selected machine not found." } unless machine
    return { success: false, alert: "Selected machine is not allocated for packing." } unless machine.packing?
    return { success: false, alert: "Selected machine is currently in use." } unless machine.inactive?

    ActiveRecord::Base.transaction do
      # Clear any existing machine checks if changing machine
      if package.machine.present? && package.machine != machine
        package.package_machine_checks.destroy_all
      end

      # Activate the machine when it's selected for packaging
      machine.update!(status: :active)
      package.update!(machine: machine)

      { success: true, notice: "Machine #{machine.name} has been assigned and activated." }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, alert: "Error selecting machine: #{e.message}" }
  rescue StandardError => e
    { success: false, alert: "An unexpected error occurred: #{e.message}" }
  end
end
