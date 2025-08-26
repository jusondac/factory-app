class UnitBatchesController < ApplicationController
  before_action :set_unit_batch, only: [ :show, :edit, :update, :destroy ]

  def index
    # Set up Ransack search
    @q = UnitBatch.includes(:product, :prepare, :produce).ransack(params[:q])

    # Get the results with pagination
    @unit_batches = @q.result
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(8)  # 8 items per page

    # Get products for filter dropdown
    @products = Product.all
  end

  def show
  end

  def new
    @unit_batch = UnitBatch.new
    @products = Product.all
  end

  def create
    @unit_batch = UnitBatch.new(unit_batch_params)

    if @unit_batch.save
      redirect_to @unit_batch, notice: "Unit batch was successfully created."
    else
      @products = Product.all
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @products = Product.all
  end

  def update
    if @unit_batch.update(unit_batch_params)
      redirect_to @unit_batch, notice: "Unit batch was successfully updated."
    else
      @products = Product.all
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @unit_batch.destroy
    redirect_to unit_batches_path, notice: "Unit batch was successfully deleted."
  end

  private

  def set_unit_batch
    @unit_batch = UnitBatch.find(params[:id])
  end

  def unit_batch_params
    params.require(:unit_batch).permit(:product_id, :status)
  end

  def current_user
    Current.session&.user
  end
end
