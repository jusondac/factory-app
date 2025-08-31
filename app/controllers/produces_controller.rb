class ProducesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view!
  before_action :set_produce, only: [ :show, :edit, :update, :destroy, :machine_checking, :update_machine_checking, :select_machine ]
  before_action :authorize_edit!, only: [ :edit, :update, :destroy, :machine_checking, :update_machine_checking, :select_machine ]

  def index
    @q = Produce.ransack(params[:q])

    # Apply tab filter
    tab = params[:tab] || "today"
    @tab = tab

    base_query = case tab
    when "today"
      @q.result.today
    when "history"
      @q.result.history
    else
      @q.result
    end

    @produces = base_query.with_includes.page(params[:page]).per(5).order(created_at: :desc)
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
      render :new, status: :unprocessable_content
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
      render :edit, status: :unprocessable_content
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

      # Automatically transition unit batch to packing status and create package
      begin
        @produce.unit_batch.update!(status: :packing)

        # Create new package with unpackage status
        package = Package.new(
          unit_batch: @produce.unit_batch,
          package_date: Date.current,
          waste_quantity: 0
        )

        if package.save
          redirect_to @produce, notice: "Production completed successfully. Package created and ready for packaging. Machine is now available for other productions."
        else
          # If package creation fails, still show success for production but warn about package
          redirect_to @produce, notice: "Production completed successfully. However, package creation failed: #{package.errors.full_messages.join(', ')}. Machine is now available for other productions."
        end
      rescue ActiveRecord::RecordInvalid => e
        # If unit batch update fails, still show success for production but warn about transition
        redirect_to @produce, notice: "Production completed successfully. However, unit batch transition to packing failed: #{e.message}. Machine is now available for other productions."
      end
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

    service = ProduceMachineCheckingService.new(produce: @produce, user: Current.user)
    result = service.get_machine_checkings_data

    if result[:success]
      @machine_checkings = result[:machine_checkings]
      @produce_machine_checks = result[:produce_machine_checks]
    else
      redirect_to @produce, alert: result[:alert]
    end
  end

  def update_machine_checking
    authorize_edit_specific!

    service = ProduceMachineCheckingService.new(
      produce: @produce,
      user: Current.user,
      machine_checking_params: machine_checking_params
    )
    result = service.perform_machine_checking

    if result[:success]
      redirect_to @produce, notice: result[:notice]
    else
      redirect_to machine_checking_produce_path(@produce), alert: result[:alert]
    end
  end

  def select_machine
    authorize_edit_specific!

    service = ProduceMachineSelectionService.new(
      produce: @produce,
      user: Current.user,
      machine_id: params[:machine_id]
    )
    result = service.select_machine

    if result[:success]
      redirect_to @produce, notice: result[:notice]
    else
      redirect_to @produce, alert: result[:alert]
    end
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
