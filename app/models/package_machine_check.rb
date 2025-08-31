class PackageMachineCheck < ApplicationRecord
  belongs_to :package
  belongs_to :machine_checking

  validates :question, presence: true
  validates :answer, presence: true

  delegate :checking_type, to: :machine_checking

  def self.ransackable_attributes(auth_object = nil)
    [ "answer", "created_at", "id", "machine_checking_id", "package_id", "question", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "machine_checking", "package" ]
  end
end
