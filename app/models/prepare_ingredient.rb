class PrepareIngredient < ApplicationRecord
  belongs_to :prepare, counter_cache: :prepare_ingredients_count

  validates :ingredient_name, presence: true
  validates :checked, inclusion: { in: [ true, false ] }

  scope :checked, -> { where(checked: true) }
  scope :unchecked, -> { where(checked: false) }

  def toggle_checked!
    ActiveRecord::Base.transaction do
      new_checked = !checked
      update!(checked: new_checked)

      # Update counter cache manually since Rails doesn't support conditional counter caches
      prepare.update_checked_ingredients_count

      # Reload prepare to ensure fresh data
      prepare.reload
    end
  end
end
