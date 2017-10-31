class Deputy < ApplicationRecord

  validates :user_email, presence: true
  validates :deputy, presence: true
end
