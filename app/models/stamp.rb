class Stamp < ApplicationRecord
  include AkerPermissionGem::Accessible

  has_many :stamp_materials, dependent: :delete_all

  validates :name, presence: true
  validates :owner_id, presence: true

  validate :validate_name_active_uniqueness, if: :active?

  before_validation :sanitise_name, :sanitise_owner
  before_save :sanitise_name, :sanitise_owner

  def active?
    deactivated_at.nil?
  end

  def deactivated?
    !active?
  end

  def deactivate!
    update_attributes!(deactivated_at: DateTime.now) if active?
  end

  def sanitise_name
    if name
      sanitised = name.strip.gsub(/\s+/, ' ')
      if sanitised != name
        self.name = sanitised
      end
    end
  end

  def sanitise_owner
    if owner_id
      sanitised = owner_id.strip.downcase
      if sanitised != owner_id
        self.owner_id = sanitised
      end
    end
  end

  private

  # Name must be unique within the scope of active stamps
  def validate_name_active_uniqueness
    if Stamp.where(name: name, deactivated_at: nil).any? { |s| s.id != id }
      errors.add(:name, "must be unique")
    end
  end
end
