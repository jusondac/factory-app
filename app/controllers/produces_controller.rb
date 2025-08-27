class ProducesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view!
  before_action :set_produce, only: [ :show, :edit, :update, :destroy, :machine_checking, :update_machine_checking, :select_machine ]
  before_action :authorize_edit!, only: [ :edit, :update, :destroy, :machine_checking, :update_machine_checking, :select_machine ]

  def index
    @q = Produce.ransack(params[:q])
    @produces = @q.result.with_includes.page(params[:page]).per(10)

    # Get checked unit batches that are ready to move to production
    @checked_unit_batches = UnitBatch.preparation
                                   .joins(:prepare)
                                   .where(prepares: { status: :checked })
                                   .where.missing(:produce)
                                   .includes(:product, :prepare)
  end

  def show
    if Current.user.worker?
      @all_production_machines = Machine.where(allocation: :production)
      @available_machines = @all_production_machines.select { |m| m.status == "inactive" }
    end
  end

  def new
    @produce = Produce.new
    @unit_batches = UnitBatch.production.includes(:product).where.missing(:produce)
  end

  def create
    @produce = Produce.new(produce_params)
    @produce.product_date = Date.current

    if @produce.save
      redirect_to @produce, notice: "Produce was successfully created."
    else
      @unit_batches = UnitBatch.production.includes(:product).where.missing(:produce)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_edit_specific!

    if @produce.machine_check?
      redirect_to @produce, alert: "Cannot edit production after machine checking is completed."
    end
  end

  def update
    authorize_edit_specific!

    return redirect_to(@produce, alert: "Cannot edit production after machine checking is completed.") if @produce.machine_check?

    if @produce.update(produce_params)
      redirect_to @produce, notice: "Produce was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_edit_specific!
    @produce.destroy
    redirect_to produces_url, notice: "Produce was successfully deleted."
  end

  def start_production
    @produce = Produce.find(params[:id])
    authorize_edit_specific!

    if @produce.unproduce? && @produce.update(status: :producing)
      redirect_to @produce, notice: "Production started successfully."
    else
      redirect_to @produce, alert: "Unable to start production."
    end
  end

  def complete_production
    @produce = Produce.find(params[:id])
    authorize_edit_specific!

    if @produce.producing? && @produce.update(status: :produced)
      # Release the machine back to inactive status when production is completed
      @produce.machine.inactive! if @produce.machine.present?
      redirect_to @produce, notice: "Production completed successfully. Machine is now available for other productions."
    else
      redirect_to @produce, alert: "Unable to complete production."
    end
  end

  def move_to_produce
    authorize_edit!

    @unit_batch = UnitBatch.find(params[:unit_batch_id])

    # Check if unit batch is in preparation status and has a checked prepare
    unless @unit_batch.preparation? && @unit_batch.prepare&.checked?
      redirect_to produces_path, alert: "Unit batch is not ready for production."
      return
    end

    # Check if produce already exists for this unit batch
    if @unit_batch.produce.present?
      redirect_to produces_path, alert: "Production record already exists for this unit batch."
      return
    end

    # Create produce record
    @produce = Produce.new(
      unit_batch: @unit_batch,
      product_date: Date.current,
      status: :unproduce
    )

    if @produce.save
      # Update unit batch status to production
      @unit_batch.update!(status: :production)
      redirect_to produces_path, notice: "Unit batch successfully moved to production."
    else
      redirect_to produces_path, alert: "Failed to create production record."
    end
  end

  def machine_checking
    authorize_edit_specific!

    unless @produce.machine.present?
      redirect_to @produce, alert: "Please select a machine first."
      return
    end

    @machine_checkings = @produce.machine.machine_checkings
    @produce_machine_checks = {}

    # Initialize existing answers
    @produce.produce_machine_checks.includes(:machine_checking).each do |check|
      @produce_machine_checks[check.machine_checking_id] = check.answer
    end
  end

  def update_machine_checking
    authorize_edit_specific!

    unless @produce.machine.present?
      redirect_to @produce, alert: "Please select a machine first."
      return
    end

    # Clear existing checks for this produce
    @produce.produce_machine_checks.destroy_all

    # Create new checks from the submitted form
    machine_checking_params.each do |checking_id, answer|
      next if answer.blank?

      machine_checking = MachineChecking.find(checking_id)

      # Handle array answers (from checkboxes) by joining them
      final_answer = answer.is_a?(Array) ? answer.reject(&:blank?).join(", ") : answer
      next if final_answer.blank?

      @produce.produce_machine_checks.create!(
        machine_checking: machine_checking,
        question: machine_checking.checking_name,
        answer: final_answer
      )
    end

    # Mark machine check as completed
    @produce.update!(machine_check: true)

    redirect_to @produce, notice: "Machine checking completed successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to machine_checking_produce_path(@produce), alert: "Error saving machine checks: #{e.message}"
  end

  def select_machine
    authorize_edit_specific!

    if @produce.machine_check?
      redirect_to @produce, alert: "Machine checking has already been completed."
      return
    end

    machine = Machine.find(params[:machine_id])

    unless machine.production?
      redirect_to @produce, alert: "Selected machine is not allocated for production."
      return
    end

    # Only allow selecting inactive machines (available machines)
    unless machine.inactive?
      redirect_to @produce, alert: "Selected machine is currently in use."
      return
    end

    # Clear any existing machine checks if changing machine
    @produce.produce_machine_checks.destroy_all if @produce.machine.present? && @produce.machine != machine

    # Activate the machine when it's selected for production
    machine.update!(status: :active)
    @produce.update!(machine: machine)
    redirect_to @produce, notice: "Machine selected and activated successfully."
  end

  private

  def set_produce
    @produce = Produce.find(params[:id])
  end

  def produce_params
    params.require(:produce).permit(:unit_batch_id, :status, :machine_id)
  end

  def machine_checking_params
    params.permit(machine_checking: {}).fetch(:machine_checking, {})
  end

  def authorize_view!
    unless Current.user.can_view_produces?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def authorize_edit!
    unless Current.user.can_edit_produces?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def authorize_edit_specific!
    unless Current.user.can_edit_produces?
      redirect_to @produce, alert: "Access denied. You can only view this produce."
    end
  end

  def authenticate_user!
    redirect_to new_session_path unless Current.user
  end
end
