class PackagesController < ApplicationController
  before_action :set_package, only: [ :show, :edit, :update, :destroy, :select_machine ]
  before_action :authorize_edit!, only: [ :edit, :update, :destroy, :select_machine ]

  def index
    @q = Package.ransack(params[:q])
    @packages = @q.result.with_includes.page(params[:page]).per(5).order(created_at: :desc)
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
    if params[:machine_id].present?
      machine = Machine.find(params[:machine_id])
      if machine.status == "inactive"
        @package.update!(machine: machine)
        machine.update!(status: "active")
        redirect_to @package, notice: "Machine #{machine.name} has been assigned and activated."
      else
        redirect_to @package, alert: "Selected machine is not available."
      end
    else
      redirect_to @package, alert: "Please select a machine."
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
