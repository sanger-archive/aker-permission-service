class Deputy < ApplicationRecord

  validates :user_email, presence: true, uniqueness: { scope: :deputy }
  validates :deputy, presence: true

  before_validation :sanitise_user, :sanitise_deputy
  before_save :sanitise_user, :sanitise_deputy

  def sanitise_user
    if user_email
      sanitised = user_email.strip.downcase
      if sanitised != user_email
        self.user_email = sanitised
      end
    end
  end

  def sanitise_deputy
    if deputy
      sanitised = deputy.strip.downcase
      if sanitised != deputy
        self.deputy = sanitised
      end
    end
  end
end
