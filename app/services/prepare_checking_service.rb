class PrepareCheckingService
  include ActiveModel::Model

  attr_accessor :prepare, :user, :prepare_ingredient_id

  validates :prepare, presence: true
  validates :user, presence: true

  def initialize(attributes = {})
    super
  end

  def start_checking
    return false unless can_start_checking?

    prepare.update!(status: :checking, checked_by: user)
    true
  end

  def cancel_checking
    return false unless can_cancel_checking?
    ActiveRecord::Base.transaction do
      prepare.update!(status: :cancelled, checked_by: nil)
      prepare.unit_batch.update!(status: :cancelled)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def complete_checking
    return false unless can_complete_checking?

    ActiveRecord::Base.transaction do
      prepare.update!(status: :checked)

      # Transition unit batch to production and create produce record
      if prepare.unit_batch.preparation?
        prepare.unit_batch.update!(status: :production)

        # Create produce record
        prepare.unit_batch.create_produce!(
          product_date: Date.current
        )
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def toggle_ingredient_check
    return false unless prepare_ingredient_id.present?
    return false unless prepare.checking?

    ingredient = prepare.prepare_ingredients.find(prepare_ingredient_id)
    ingredient.toggle_checked!

    # Reload prepare to get fresh counter data
    prepare.reload
    complete_checking_if_all_done
  end

  def can_start_checking?
    return false unless prepare.can_be_checked_by?(user)

    if errors.any?
      errors.add(:base, "You cannot check this preparation.")
      return false
    end

    true
  end

  def can_cancel_checking?
    return false unless prepare.checking? && prepare.checked_by == user

    if errors.any?
      errors.add(:base, "You cannot cancel this preparation.")
      return false
    end

    true
  end

  def can_complete_checking?
    return false unless prepare.checking? && prepare.checked_by == user

    if errors.any?
      errors.add(:base, "You cannot complete this preparation.")
      return false
    end

    true
  end

  private

  def complete_checking_if_all_done
    if prepare.all_ingredients_checked?
      ActiveRecord::Base.transaction do
        prepare.update!(status: :checked)

        # Transition unit batch to production and create produce record
        if prepare.unit_batch.preparation?
          prepare.unit_batch.update!(status: :production)

          # Create produce record
          prepare.unit_batch.create_produce!(
            product_date: Date.current
          )
        end
      end
      :completed
    else
      :in_progress
    end
  rescue ActiveRecord::RecordInvalid
    :error
  end
end
