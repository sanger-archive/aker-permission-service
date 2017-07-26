class Stamp < ApplicationRecord
  include AkerPermissionGem::Accessible

  has_many :stamp_materials, dependent: :delete_all

  after_destroy do
    permissions.destroy_all
  end

  validates :name, presence: true, uniqueness: true
  validates :owner_id, presence: true
end
