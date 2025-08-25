class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :products, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { worker: 0, tester: 1, supervisor: 2, manager: 3, head: 4 }, default: :worker

  def can_create_products?
    manager? || head?
  end
end
