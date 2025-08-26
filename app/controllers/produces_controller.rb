class ProducesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view!
  before_action :set_produce, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_edit!, only: [ :edit, :update, :destroy ]

  def index
    @q = Produce.ransack(params[:q])
    @produces = @q.result.with_includes.page(params[:page]).per(10)
  end

  def show
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
  end

  def update
    authorize_edit_specific!

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
      redirect_to @produce, notice: "Production completed successfully."
    else
      redirect_to @produce, alert: "Unable to complete production."
    end
  end

  private

  def set_produce
    @produce = Produce.find(params[:id])
  end

  def produce_params
    params.require(:produce).permit(:unit_batch_id, :status)
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
