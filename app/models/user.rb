class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Validations
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Normalize email before save
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
