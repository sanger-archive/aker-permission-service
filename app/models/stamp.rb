class Stamp < ApplicationRecord
  include AkerPermissionGem::Accessible

  has_many :stamp_materials

  validates :name, presence: true, uniqueness: true
  validates :owner_id, presence: true
end
