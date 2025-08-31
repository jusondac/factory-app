class PackageMachineCheck < ApplicationRecord
  belongs_to :package
  belongs_to :machine_checking
end
