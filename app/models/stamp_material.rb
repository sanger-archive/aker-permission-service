class StampMaterial < ApplicationRecord
  belongs_to :stamp

  validates :material_uuid, presence: true, uniqueness: { scope: :stamp_id }
end
