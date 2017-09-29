class Stamp < ApplicationRecord
  include AkerPermissionGem::Accessible

  has_many :stamp_materials, dependent: :delete_all

  validates :name, presence: true
  validates :owner_id, presence: true

  validate :validate_name_active_uniqueness, if: :active?

  def active?
    deactivated_at.nil?
  end

  def deactivated?
    !active?
  end

  def deactivate!
    update_attributes!(deactivated_at: DateTime.now) if active?
  end

  private

  # Name must be unique within the scope of active stamps
  def validate_name_active_uniqueness
    if Stamp.where("name = ? AND deactivated_at is NULL", name).exists?
      errors.add(:name, "must be unique")
    end
  end
end
