class PrepareIngredient < ApplicationRecord
  belongs_to :prepare

  validates :ingredient_name, presence: true
  validates :checked, inclusion: { in: [ true, false ] }

  scope :checked, -> { where(checked: true) }
  scope :unchecked, -> { where(checked: false) }

  def toggle_checked!
    update!(checked: !checked)
  end
end
