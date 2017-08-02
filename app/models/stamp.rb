class Stamp < ApplicationRecord
  include AkerPermissionGem::Accessible

  has_many :stamp_materials, dependent: :delete_all

  validates :name, presence: true, uniqueness: true
  validates :owner_id, presence: true

  def active?
    deactivated_at.nil?
  end

  def deactivated?
    !active?
  end

  def deactivate!
    update_attributes!(deactivated_at: DateTime.now) if active?
  end
end
