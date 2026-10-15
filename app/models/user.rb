class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :event_types, dependent: :destroy
  has_many :availability_rules, dependent: :destroy
  has_many :bookings, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name&.parameterize
  end
end
