require 'rails_helper'

RSpec.describe Stamp, type: :model do

  describe 'validation' do
    context 'when creating a stamp' do
      it 'is not valid without a name' do
        expect(build(:stamp, name: nil)).not_to be_valid
      end

      it 'is not valid without an owner_id' do
        expect(build(:stamp, owner_id: nil)).not_to be_valid
      end

      it 'is valid with a unique name (within the scope of active stamps)' do
        stamp = create(:stamp)
        stamp.deactivate!
        expect(build(:stamp, name: stamp.name)).to be_valid
      end

      it 'is not valid with a duplicate name (within the scope of active stamps)' do
        stamp = create(:stamp)
        expect(build(:stamp, name: stamp.name)).not_to be_valid
      end
    end

    context 'when updating a stamp' do
      it 'is valid with a unique name (within the scope of active stamps)' do
        stamp = create(:stamp)
        stamp.deactivate!
        stamp1 = create(:stamp)
        expect(stamp1.update_attributes(name: stamp.name)).to eq true
      end

      it 'is not valid with a duplicate name (within the scope of active stamps)' do
        stamp = create(:stamp)
        stamp1 = create(:stamp)
        expect(stamp1.update_attributes(name: stamp.name)).to eq false
      end
    end

  end

  describe '#destroy' do
    before do
      @stamp = create(:stamp)
      @perm = @stamp.permissions.create(permission_type: :consume, permitted: 'jeff')
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

  describe '#deactivate!' do
    it 'works' do
      stamp = create(:stamp)
      expect(stamp).to be_active
      expect(stamp).not_to be_deactivated
      stamp.deactivate!
      expect(stamp).not_to be_active
      expect(stamp).to be_deactivated
    end

    context 'when the stamp is already deactivated' do
      it 'does not alter the deactivated_at time' do
        time = DateTime.new(2017, 1, 1)
        stamp = create(:stamp, deactivated_at: time)
        expect(stamp).to be_deactivated
        stamp.deactivate!
        expect(stamp).to be_deactivated
        expect(stamp.deactivated_at).to eq(time)
      end
    end

  end
end
