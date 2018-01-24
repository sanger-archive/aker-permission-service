require 'rails_helper'

RSpec.describe PermissionChecker do
  def make_stamp(permitted, permission_type)
    stamp = create(:stamp)
    stamp.permissions.create(permitted: permitted,
                             permission_type: permission_type)
    create(:stamp_material, stamp: stamp)
    stamp
  end

  def set_material_users(uuid, owner, submitter = "submitter@sanger.ac.uk")
    @material_owners ||= {}
    @material_owners[uuid] = owner
    @material_submitters ||= {}
    @material_submitters[uuid] = submitter
  end

  let(:response_headers) { { 'Content-Type' => 'application/json' } }

  let(:json_schema) do
    {
      required: %w[supplier_name scientific_name gender donor_id phenotype],
      type: 'object',
      properties: {
        available: { default: false, required: false, type: 'boolean' },
        hmdmc_not_required_confirmed_by: { not_blank: true, required: false,
                                           type: 'string' },
        scientific_name: { required: true, type: 'string',
                           allowed: ['Homo sapiens', 'Mus musculus'] },
        gender: { required: true, type: 'string',
                  allowed: %w[male female unknown] },
        date_of_receipt: { type: 'string', format: 'date' },
        material_type: { type: 'string', allowed: %w[blood dna] },
        hmdmc_set_by: { not_blank: true, required: false, type: 'string',
                        required_with_hmdmc: true },
        hmdmc: { hmdmc_format: true, type: 'string', required: false },
        donor_id: { required: true, type: 'string' },
        phenotype: { required: true, type: 'string' },
        supplier_name: { required: true, type: 'string' },
        owner_id: { required: true, type: 'string' },
        submitter_id: { required: true, type: 'string' }
      }
    }.to_json
  end

  def stub_materials_service
    stub_request(:get, Rails.application.config.material_url + '/materials/json_schema').
      to_return(status: 200, body: json_schema, headers: response_headers)

    stub_request(:post, Rails.application.config.material_url + '/materials/search')
      .to_return do |request|
        body = JSON.parse(request.body)
        where = body['where']
        ids = where['_id']['$in']
        if where.include?('owner_id')
          # Request made by owned_material_uuids
          owners = where['owner_id']['$in']
          ids = ids.select { |id| owners.include?(@material_owners[id]) }
          result = { _items: ids.map { |id| { _id: id } } }
        else
          # Request made by deputised_material_uuids or submitted_material_uuids
          result = { _items: ids.map { |id| { _id: id, owner_id: @material_owners[id], submitter_id: @material_submitters[id] } } }
        end
        { status: 200, body: result.to_json, headers: response_headers }
      end
  end

  describe '#check' do
    before do
      @stamp1 = make_stamp('jeff@sanger.ac.uk', :edit)
      @stamp2 = make_stamp('beta@sanger.ac.uk', :edit)
      @stamp3 = make_stamp('jeff@sanger.ac.uk', :read)
      @stamp4 = make_stamp('dirk@sanger.ac.uk', :edit)

      @permitted_uuids = [@stamp1.stamp_materials.first.material_uuid,
                          @stamp2.stamp_materials.first.material_uuid]
      @unpermitted_uuids = [@stamp3.stamp_materials.first.material_uuid,
                            @stamp4.stamp_materials.first.material_uuid,
                            SecureRandom.uuid]
      @material_uuids = @permitted_uuids + @unpermitted_uuids

      # All material UUIDs must also have an owner (sample guardian)
      @material_uuids.each { |uuid| set_material_users(uuid, 'default@sanger.ac.uk') }

      stub_materials_service
    end

    context 'when the materials are not all permitted' do
      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @material_uuids)).to eq(false)
      end

      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @material_uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(@unpermitted_uuids)
      end
    end

    context 'when the materials are all permitted' do
      it 'should return true' do
        expect(PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @permitted_uuids)).to eq(true)
      end

      it 'should have an empty unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @permitted_uuids)
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
        expect(PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @material_uuids)).to eq(false)
      end

      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['alpha@sanger.ac.uk', 'beta@sanger.ac.uk', 'jeff@sanger.ac.uk'], @material_uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(@unpermitted_uuids)
      end
    end

    context 'when the materials are owned by the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'omega@sanger.ac.uk' }
      before do
        uuids.each { |uuid| set_material_users(uuid, owner) }
      end

      it 'should return true' do
        expect(PermissionChecker.check(:edit, ['xyz@sanger.ac.uk', owner, 'zyx@sanger.ac.uk'], uuids)).to eq(true)
      end

      it 'should have an empty unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['xyz@sanger.ac.uk', owner, 'zyx@sanger.ac.uk'], uuids)
        expect(PermissionChecker.unpermitted_uuids).to be_empty
      end
    end

    context 'when the materials are owned by someone else' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'omega@sanger.ac.uk' }
      before do
        uuids.each { |uuid| set_material_users(uuid, owner) }
      end

      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['xyz@sanger.ac.uk', 'zyx@sanger.ac.uk'], uuids)).to eq(false)
      end

      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['xyz@sanger.ac.uk', 'zyx@sanger.ac.uk'], uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(uuids)
      end
    end

    context 'when the materials are owned by someone who has deputised the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'boss@sanger.ac.uk' }
      let(:deputy_user) { 'deputy@sanger.ac.uk' }
      let(:deputy_group) { 'science_team' }

      before do
        uuids.each { |uuid| set_material_users(uuid, owner) }
        create(:deputy, user_email: owner, deputy: deputy_user)
        create(:deputy, user_email: owner, deputy: deputy_group)
      end

      describe "through the user's email address" do
        it 'should return true' do
          expect(PermissionChecker.check(:edit, [deputy_user], uuids)).to eq(true)
        end
      end

      describe 'through a group the user is in' do
        it 'should return true' do
          expect(PermissionChecker.check(:edit, [deputy_group], uuids)).to eq(true)
        end
      end

      describe "through both the user's email and their group" do
        it 'should return true' do
          expect(PermissionChecker.check(:edit, [deputy_user, deputy_group], uuids)).to eq(true)
        end
      end
    end

    context 'when the materials are owned by someone who has NOT deputised the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'boss@sanger.ac.uk' }
      let(:not_deputy_user) { 'not_deputy@sanger.ac.uk' }
      let(:not_deputy_group) { 'science_team' }

      before do
        uuids.each { |uuid| set_material_users(uuid, owner) }
      end

      describe "through the user's email address" do
        it 'should return false' do
          expect(PermissionChecker.check(:edit, [not_deputy_user], uuids)).to eq(false)
        end
      end

      describe 'through a group the user is in' do
        it 'should return false' do
          expect(PermissionChecker.check(:edit, [not_deputy_group], uuids)).to eq(false)
        end
      end

      describe "through both the user's email and their group" do
        it 'should return false' do
          expect(PermissionChecker.check(:edit, [not_deputy_user, not_deputy_group], uuids)).to eq(false)
        end
      end
    end

    context 'when the materials were submitted by the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'boss@sanger.ac.uk' }
      let(:submitter) { 'submitter1@sanger.ac.uk' }

      before do
        uuids.each { |uuid| set_material_users(uuid, owner, submitter) }
      end

      it 'should return true' do
        expect(PermissionChecker.check(:edit, [submitter], uuids)).to eq(true)
      end
    end

    context 'when the materials were NOT submitted by the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'boss@sanger.ac.uk' }
      let(:submitter) { 'submitter1@sanger.ac.uk' }

      before do
        uuids.each { |uuid| set_material_users(uuid, owner, submitter) }
      end

      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['random@sanger.ac.uk'], uuids)).to eq(false)
      end
    end

  end
end
