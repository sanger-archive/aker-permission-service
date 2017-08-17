require 'rails_helper'

RSpec.describe PermissionChecker do
  def make_stamp(permitted, permission_type)
    stamp = create(:stamp)
    stamp.permissions.create(permitted: permitted, permission_type: permission_type)
    create(:stamp_material, stamp: stamp)
    stamp
  end

  def set_material_owner(uuid, owner)
    @material_owners ||= {}
    @material_owners[uuid] = owner
  end

  let(:response_headers) { {'Content-Type' => 'application/json'} }

  let(:json_schema) do
    {
      required: ["supplier_name", "scientific_name", "gender", "donor_id", "phenotype"],
      type:"object",
      properties: {
        available: {default:false, required:false, type:"boolean"},
        hmdmc_not_required_confirmed_by: {not_blank:true, required:false, type:"string"},
        scientific_name: {required:true, type:"string", allowed:["Homo sapiens", "Mus musculus"]},
        gender: {required:true, type:"string", allowed:["male", "female", "unknown"]},
        date_of_receipt: {type:"string", format:"date"},
        material_type: {type:"string", allowed:["blood", "dna"]},
        hmdmc_set_by: {not_blank:true, required:false, type:"string", required_with_hmdmc:true},
        hmdmc: {hmdmc_format:true, type:"string", required:false},
        donor_id: {required:true, type:"string"},
        phenotype: {required:true, type:"string"},
        supplier_name: {required:true, type:"string"},
      }
    }.to_json
  end

  def stub_materials_service
    stub_request(:get, Rails.application.config.material_url+'/materials/json_schema').
      to_return(status: 200, body: json_schema, headers: response_headers)

    @material_owners ||= {}
    stub_request(:post, Rails.application.config.material_url+'/materials/search').
      to_return do |request|
        body = JSON.parse(request.body)
        where = body['where']
        ids = where['_id']['$in']
        owners = where['owner_id']['$in']
        ids = ids.select { |id| owners.include?(@material_owners[id]) }
        result = { _items: ids.map { |id| { _id: id } } }

        { status: 200, body: result.to_json, headers: response_headers }
      end
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

      stub_materials_service
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

    context 'when the materials are owned by the requesting user' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'omega@sanger.ac.uk' }
      before do
        uuids.each { |uuid| set_material_owner(uuid, owner) }
      end
      it 'should return true' do
        expect(PermissionChecker.check(:edit, ['xyz', owner, 'zyx'], uuids)).to eq(true)
      end
      it 'should have an empty unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['xyz', owner, 'zyx'], uuids)
        expect(PermissionChecker.unpermitted_uuids).to be_empty
      end
    end

    context 'when the materials are owned by someone else' do
      let(:uuids) { (0...2).map { SecureRandom.uuid } }
      let(:owner) { 'omega@sanger.ac.uk' }
      before do
        uuids.each { |uuid| set_material_owner(uuid, owner) }
      end
      it 'should return false' do
        expect(PermissionChecker.check(:edit, ['xyz', 'zyx'], uuids)).to eq(false)
      end
      it 'should put the unpermitted materials into the unpermitted_uuids attribute' do
        PermissionChecker.check(:edit, ['xyz', 'zyx'], uuids)
        expect(PermissionChecker.unpermitted_uuids).to eq(uuids)
      end
    end

  end

end
