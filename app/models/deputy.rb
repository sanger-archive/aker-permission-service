class Deputy < ApplicationRecord

  validates :user_email, presence: true, uniqueness: { scope: :deputy }
  validates :deputy, presence: true
end
