class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :created_prepares, class_name: "Prepare", foreign_key: "created_by_id", dependent: :destroy
  has_many :checked_prepares, class_name: "Prepare", foreign_key: "checked_by_id", dependent: :nullify

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { worker: 0, tester: 1, supervisor: 2, manager: 3, head: 4 }, default: :worker

  def can_create_products?
    manager? || head?
  end

  def can_edit_product?(product)
    (manager? || head?) || product.user == self
  end

  def can_create_prepares?
    supervisor? || manager? || head?
  end

  def can_check_prepares?
    worker?
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email_address", "id", "id_value", "password_digest", "role", "updated_at"]
  end
end
