require 'rails_helper'

RSpec.describe Stamp, type: :model do

  describe 'validation' do
    it 'is not valid without a name' do
      expect(build(:stamp, name: nil)).not_to be_valid
    end

    it 'is not valid without a unique name' do
      stamp = create(:stamp)
      expect(build(:stamp, name: stamp.name)).not_to be_valid
    end

    it 'is not valid without an owner_id' do
      expect(build(:stamp, owner_id: nil)).not_to be_valid
    end
  end

  describe '#destroy' do
    before do
      @stamp = create(:stamp)
      @perm = @stamp.permissions.create(permission_type: :spend, permitted: 'jeff')
      @mat = create(:stamp_material, stamp: @stamp)

      @stamp.destroy!
    end

    it 'destroys the stamp' do
      expect(Stamp.where(id: @stamp.id).first).to be_nil
    end

    it 'destroys the permissions' do
      expect(AkerPermissionGem::Permission.where(id: @perm.id).first).to be_nil
    end

    it 'destroys the stamp materials' do
      expect(StampMaterial.where(id: @mat.id).first).to be_nil
    end
  end
end
