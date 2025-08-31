class PackagesController < ApplicationController
  before_action :set_package, only: [ :show, :edit, :update, :destroy, :select_machine, :machine_checking, :update_machine_checking, :start_packaging, :complete_packaging ]
  before_action :authorize_view!, only: [ :index, :show ]
  before_action :authorize_edit!, only: [ :edit, :update, :destroy, :select_machine, :machine_checking, :update_machine_checking, :start_packaging, :complete_packaging ]
  def machine_checking
    service = PackageMachineCheckingService.new(package: @package, user: Current.user)
    result = service.get_machine_checkings_data

    if result[:success]
      @machine_checkings = result[:machine_checkings]
      @package_machine_checks = result[:package_machine_checks]
    else
      redirect_to @package, alert: result[:alert]
    end
  end

  def update_machine_checking
    service = PackageMachineCheckingService.new(
      package: @package,
      user: Current.user,
      machine_checking_params: params.permit(machine_checking: {}).fetch(:machine_checking, {})
    )
    result = service.perform_machine_checking

    if result[:success]
      redirect_to @package, notice: result[:notice]
    else
      redirect_to machine_checking_package_path(@package), alert: result[:alert]
    end
  end

  def start_packaging
    if @package.unpackage? && @package.machine_check? && @package.update(status: :packaging)
      redirect_to @package, notice: "Packaging started successfully."
    else
      redirect_to @package, alert: "Unable to start packaging. Machine checking must be completed first."
    end
  end

  def complete_packaging
    if @package.packaging? && @package.update(status: :package)
      @package.machine.inactive! if @package.machine.present?
      redirect_to @package, notice: "Packaging completed successfully. Machine is now available."
    else
      redirect_to @package, alert: "Unable to complete packaging."
    end
  end

  def index
    service_result = PackageIndexService.new(params).call

    @packages = service_result[:packages]
    @q = service_result[:search]
    @total_count = service_result[:total_count]
    @current_page = service_result[:current_page]
    @total_pages = service_result[:total_pages]
    @tab = params[:tab] || "today"

    # For AJAX requests
    respond_to do |format|
      format.html
      format.json { render json: { packages: @packages, total_count: @total_count } }
    end
  end

  def show
    if Current.user.worker?
      @all_packaging_machines = Machine.where(allocation: :packing)
      @available_machines = @all_packaging_machines.select { |m| m.status == "inactive" }
    end
  end

  def new
    @package = Package.new
    @unit_batches = UnitBatch.packing.includes(:product).where.missing(:package)
  end

  def create
    @package = Package.new(package_params)
    @package.package_date = Date.current

    if @package.save
      redirect_to @package, notice: "Package was successfully created."
    else
      @unit_batches = UnitBatch.packing.includes(:product).where.missing(:package)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @package.update(package_params)
      redirect_to @package, notice: "Package was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @package.destroy
    redirect_to packages_url, notice: "Package was successfully deleted."
  end

  def select_machine
    service = PackageMachineSelectionService.new(
      package: @package,
      user: Current.user,
      machine_id: params[:machine_id]
    )
    result = service.select_machine

    if result[:success]
      redirect_to @package, notice: result[:notice]
    else
      redirect_to @package, alert: result[:alert]
    end
  end

  private

  def set_package
    @package = Package.find(params[:id])
  end

  def package_params
    params.require(:package).permit(:unit_batch_id, :machine_id, :waste_quantity)
  end

  def authorize_view!
    redirect_to root_path, alert: "Access denied." unless Current.user.can_view_packages?
  end

  def authorize_edit!
    redirect_to packages_path, alert: "Access denied." unless Current.user.can_edit_packages?
  end
end
