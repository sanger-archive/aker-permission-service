class Deputy < ApplicationRecord

  validates :user_email, presence: true, uniqueness: { scope: :deputy, message: "must not already be your deputy" }
  validates :deputy, presence: true
  validate :validate_not_self_assignment

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

  private

  # Prevent someone from assigning themself as a deputy
  def validate_not_self_assignment
    errors.add(:deputy, 'cannot be yourself') if user_email == deputy
  end
end
