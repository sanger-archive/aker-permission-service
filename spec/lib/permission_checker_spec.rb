require 'rails_helper'

RSpec.describe PermissionChecker do
  def make_stamp(permitted, permission_type)
    stamp = create(:stamp)
    stamp.permissions.create(permitted: permitted, permission_type: permission_type)
    create(:stamp_material, stamp: stamp)
    stamp
  end

  describe '#check' do
    before do
      @stamp1 = make_stamp('jeff', :edit)
      @stamp2 = make_stamp('beta', :edit)
      @stamp3 = make_stamp('jeff', :read)
      @stamp4 = make_stamp('dirk', :edit)

      @permitted_uuids = [@stamp1.stamp_materials.first.material_uuid, @stamp2.stamp_materials.first.material_uuid]
      @unpermitted_uuids = [@stamp3.stamp_materials.first.material_uuid, @stamp4.stamp_materials.first.material_uuid, SecureRandom.uuid]
      @material_uuids = @permitted_uuids + @unpermitted_uuids
    end

    context 'when the materials are not all permitted' do
      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @material_uuids)).to eq(false)
      end

      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @material_uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(@unpermitted_uuids)
      end
    end

    context 'when the materials are all permitted' do
      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @permitted_uuids)).to eq(true)
      end

      it 'should have an empty unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @permitted_uuids)
        expect(PermissionChecker.unpermitted_uuids).to be_empty
      end
    end

    context 'when the stamp is deactivated' do
      before do
        @stamp1.deactivate!
        @unpermitted_uuids = [@stamp1.stamp_materials.first.material_uuid]
        @material_uuids = @permitted_uuids
      end

      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @material_uuids)).to eq(false)
      end

      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha', 'beta', 'jeff'], @material_uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(@unpermitted_uuids)
      end
    end

  end

end
