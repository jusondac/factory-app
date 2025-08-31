class PackageMachineCheckingService
  include ActiveModel::Model

  attr_accessor :package, :user, :machine_checking_params

  validates :package, presence: true
  validates :user, presence: true

  def initialize(attributes = {})
    super
  end

  def perform_machine_checking
    return { success: false, alert: "Please select a machine first." } unless package.machine.present?
    return { success: false, alert: "Machine checking has already been completed." } if package.machine_check?

    ActiveRecord::Base.transaction do
      # Clear existing checks for this package
      package.package_machine_checks.destroy_all

      # Create new checks from the submitted form
      machine_checking_params.each do |checking_id, answer|
        next if answer.blank?

        machine_checking = MachineChecking.find(checking_id)

        # Handle array answers (from checkboxes) by joining them
        final_answer = answer.is_a?(Array) ? answer.reject(&:blank?).join(", ") : answer
        next if final_answer.blank?

        package.package_machine_checks.create!(
          machine_checking: machine_checking,
          question: machine_checking.checking_name,
          answer: final_answer
        )
      end

      # Mark machine check as completed and update status
      package.update!(status: :packaging, machine_check: true)

      { success: true, notice: "Machine checking completed. You can now start packaging." }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, alert: "Error saving machine checks: #{e.message}" }
  rescue StandardError => e
    { success: false, alert: "An unexpected error occurred: #{e.message}" }
  end

  def get_machine_checkings_data
    return { success: false, alert: "Please select a machine first." } unless package.machine.present?
    return { success: false, alert: "Machine checking has already been completed." } if package.machine_check?

    machine_checkings = package.machine.machine_checkings
    package_machine_checks = {}

    # Initialize existing answers
    package.package_machine_checks.includes(:machine_checking).each do |check|
      package_machine_checks[check.machine_checking_id] = check.answer
    end

    { success: true, machine_checkings: machine_checkings, package_machine_checks: package_machine_checks }
  end
end
