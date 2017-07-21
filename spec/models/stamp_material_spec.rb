require 'rails_helper'

RSpec.describe StampMaterial, type: :model do

  describe 'validation' do
    it 'is not valid without a material_uuid' do
      expect(build(:stamp_material, material_uuid: nil)).not_to be_valid
    end

    it 'does not allow you to add the duplicate material_uuids to a stamp' do
      stamp = create(:stamp)
      stamp_material = create(:stamp_material, stamp: stamp)
      invalid_sm = build(:stamp_material, stamp: stamp, material_uuid: stamp_material.material_uuid)
      expect(invalid_sm).to_not be_valid
    end

    it 'is not valid without a stamp' do
      expect(build(:stamp_material, stamp: nil)).to_not be_valid
    end
  end
end
