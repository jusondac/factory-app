class MachinesController < ApplicationController
  before_action :require_authentication
  before_action :require_manager_access
  before_action :set_machine, only: [:show, :edit, :update, :destroy]

  def index
    @q = Machine.includes(:machine_checkings).ransack(params[:q])
    @machines = @q.result.order(:name).page(params[:page]).per(10)
  end

  def show
  end

  def new
    @machine = Machine.new
    @machine.machine_checkings.build
  end

  def create
    @machine = Machine.new(machine_params)
    
    if @machine.save
      redirect_to @machine, notice: 'Machine was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @machine.update(machine_params)
      redirect_to @machine, notice: 'Machine was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @machine.destroy
    redirect_to machines_url, notice: 'Machine was successfully deleted.'
  end

  private

  def set_machine
    @machine = Machine.find(params[:id])
  end

  def machine_params
    params.require(:machine).permit(
      :name, :status,
      machine_checkings_attributes: [:id, :checking_name, :checking_type, :checking_value, :_destroy]
    )
  end

  def require_manager_access
    unless Current.user&.manager? || Current.user&.head?
      redirect_to root_path, alert: 'Access denied. Manager privileges required.'
    end
  end
end
