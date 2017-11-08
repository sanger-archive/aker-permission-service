require 'rails_helper'

RSpec.describe 'api/v1/stamps', type: :request do
  let(:vnd) { 'application/vnd.api+json' }
  let(:user) { 'me@here.com' }
  let(:groups) { ['world', 'pirates'] }
  let(:owner) { 'owner@here.com' }

  let(:jwt) do
    JWT.encode({ data: { 'email' => user, 'groups' => groups }}, Rails.configuration.jwt_secret_key, 'HS256')
  end

  let(:headers) do
    {
      'Content-Type' => vnd,
      'Accept' => vnd,
      'HTTP_X_AUTHORISATION' => jwt
    }
  end

  let(:body) do
    if response.body.present?
      JSON.parse(response.body, symbolize_names: true)
    else
      {}
    end
  end
  let(:data) { body[:data] }
  let(:errors) { body[:errors] }

  before do
    @stamps = create_list(:stamp, 3, owner_id: owner)
    @stamp = @stamps.first
    @stamp.permissions.create!(permission_type: :consume, permitted: 'pirates')
    create(:stamp_material, stamp: @stamp)
    @stamps[2].deactivate!
    @active_stamps = @stamps[0,2]
  end

  describe 'GET #index' do
    before do
      get api_v1_stamps_path, headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'should contain the correct number of active stamps' do
      expect(data.length).to eq(@active_stamps.length)
    end

    it 'should have the correct active stamp ids' do
      expect(data.pluck(:id)).to match_array(@active_stamps.map(&:id))
    end
  end

  describe 'GET #show' do
    context 'when the stamp is active' do
      before do
        get api_v1_stamp_path(@stamp.id), headers: headers
      end

      it { expect(response).to have_http_status(:ok) }

      it 'has the stamp id' do
        expect(data[:id]).to eq(@stamp.id)
      end
      it 'has the correct attributes' do
        expect(data[:attributes][:name]).to eq(@stamp.name)
        expect(data[:attributes][:"owner-id"]).to eq(@stamp.owner_id)
      end
      it 'has the correct relationships' do
        expect(data[:relationships].length).to eq(2)
        expect(data[:relationships].keys).to match_array([:materials, :permissions])
      end
    end
    context 'when the stamp is not active' do
      before do
        @stamp.deactivate!
        get api_v1_stamp_path(@stamp.id), headers: headers
      end

      it { expect(response).to have_http_status(:gone) }
    end
  end

  describe 'GET permissions' do
    before do
      get api_v1_stamp_permissions_path(@stamp.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the permission' do
      expect(data.length).to eq(1)
      attributes = data.first[:attributes]
      permission = @stamp.permissions.first
      expect(attributes[:'permission-type'].to_sym).to eq(permission.permission_type.to_sym)
      expect(attributes[:permitted]).to eq(permission.permitted)
    end
  end

  describe 'GET materials' do
    before do
      get api_v1_stamp_materials_path(@stamp.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the material' do
      expect(data.length).to eq(1)
      attributes = data.first[:attributes]
      material = @stamp.stamp_materials.first
      expect(attributes[:'material-uuid']).to eq(material.material_uuid)
    end
  end

  describe 'GET relationships/permissions' do
    before do
      get api_v1_stamp_relationships_permissions_path(@stamp.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the permission' do
      expect(data.length).to eq(1)
      expect(data.first[:id]).to eq(@stamp.permissions.first.id.to_s)
    end
  end

  describe 'GET relationships/materials' do
    before do
      get api_v1_stamp_relationships_materials_path(@stamp.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the material' do
      expect(data.length).to eq(1)
      expect(data.first[:id]).to eq(@stamp.stamp_materials.first.id.to_s)
    end
  end

  describe 'PUT #update' do
    context 'when I own the stamp' do
      let(:owner) { user }

      context 'when the name is being changed' do
        before do
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
          put api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:ok) }

        it 'contains the stamp' do
          expect(data[:id]).to eq(@stamp.id)
          expect(data[:attributes][:name]).to eq('meringue')
        end

        it 'does not alter the owner' do
          expect(data[:attributes][:'owner-id']).to eq(owner)
        end

        it 'correctly updates the stamp' do
          @stamp.reload
          expect(@stamp.name).to eq('meringue')
          expect(@stamp.owner_id).to eq(owner)
        end
      end

      context 'when the stamp is deactivated' do
        before do
          @name = @stamp.name
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
          @stamp.deactivate!
          put api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:gone) }

        it 'does not alter the stamp' do
          expect(@stamp.name).to eq(@name)
        end
      end

      context 'when a new owner is specified' do
        before do
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue", 'owner-id': 'jeff' } }
          put api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:bad_request) }

        it 'contains an appropriate error' do
          expect(errors).not_to be_empty
          expect(errors.first[:detail]).to match(/owner[_-]id/)
        end
      end

    end

    context 'when I do not own the stamp' do
      before do
        @old_stamp_name = @stamp.name
        data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
        put api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
      end

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not change the stamp' do
        expect(@stamp.reload.name).to eq(@old_stamp_name)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when I own the stamp' do
      let(:owner) { user }

      context 'when the name is being changed' do
        before do
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
          patch api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:ok) }

        it 'contains the stamp' do
          expect(data[:id]).to eq(@stamp.id)
          expect(data[:attributes][:name]).to eq('meringue')
        end

        it 'does not alter the owner' do
          expect(data[:attributes][:'owner-id']).to eq(owner)
        end

        it 'correctly updates the stamp' do
          @stamp.reload
          expect(@stamp.name).to eq('meringue')
          expect(@stamp.owner_id).to eq(owner)
        end
      end

      context 'when the stamp is deactivated' do
        before do
          @name = @stamp.name
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
          @stamp.deactivate!
          patch api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:gone) }

        it 'does not alter the stamp' do
          expect(@stamp.name).to eq(@name)
        end
      end

      context 'when a new owner is specified' do
        before do
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue", 'owner-id': 'jeff' } }
          patch api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:bad_request) }

        it 'contains an appropriate error' do
          expect(errors).not_to be_empty
          expect(errors.first[:detail]).to match(/owner[_-]id/)
        end
      end

      context 'when the stamp is deactivated' do
        before do
          @name = @stamp.name
          @stamp.deactivate!
          data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
          patch api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
        end

        it { expect(response).to have_http_status(:gone) }

        it 'does not update the stamp' do
          expect(@stamp.reload.name).to eq @name
        end
      end

    end

    context 'when I do not own the stamp' do
      before do
        @old_stamp_name = @stamp.name
        data = { id: @stamp.id, type: 'stamps', attributes: { name: "meringue" } }
        patch api_v1_stamp_path(@stamp.id), params: { data: data }.to_json, headers: headers
      end

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not change the stamp' do
        expect(@stamp.reload.name).to eq(@old_stamp_name)
      end
    end
  end

  describe 'DELETE #remove' do
    context 'when I own the stamp' do
      let(:owner) { user }

      context 'when the stamp is active' do
        before do
          @stamp_id = @stamps.second.id
          delete api_v1_stamp_path(@stamp_id), headers: headers
        end

        it { expect(response).to have_http_status(:no_content) }

        it 'deactivates the model' do
          expect(Stamp.where(id: @stamp_id).first).to be_deactivated
        end
      end

      context 'when the stamp is already deactivated' do
        before do
          @stamps.second.deactivate!
          @stamp_id = @stamps.second.id
          delete api_v1_stamp_path(@stamp_id), headers: headers
        end

        it { expect(response).to have_http_status(:gone) }

        it 'is still deactivated' do
          expect(Stamp.where(id: @stamp_id).first).to be_deactivated
        end
      end
    end

    context 'when I do not own the stamp' do
      before do
        @stamp_id = @stamps.second.id
        delete api_v1_stamp_path(@stamp_id), headers: headers
      end

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not deactivate the model' do
        expect(Stamp.where(id: @stamp_id).first).to be_active
      end
    end

    context 'when I own the stamp and it has permissions and materials' do
      let(:owner) { user }

      before do
        @perm_id = @stamp.permissions.first.id
        @mat_id = @stamp.stamp_materials.first.id
        delete api_v1_stamp_path(@stamp.id), headers: headers
      end

      it { expect(response).to have_http_status(:no_content) }

      it 'deactivates the model' do
        expect(Stamp.where(id: @stamp.id).first).to be_deactivated
      end
    end
  end

  describe 'POST #create' do
    let(:stamp_name) { 'Marzipan' }

    before do
      post api_v1_stamps_path, params: { data: postdata }.to_json, headers: headers
    end

    context 'when the request is correct' do
      let(:postdata) do
        {
          type: 'stamps',
          attributes: { name: stamp_name },
        }
      end

      it { expect(response).to have_http_status(:created) }

      it 'should include the stamp in the response' do
        expect(data[:id]).not_to be_nil
        atr = data[:attributes]
        expect(atr[:name]).to eq(stamp_name)
        expect(atr[:'owner-id']).to eq(user)
      end

      it 'should have created the stamp' do
        s = Stamp.find(data[:id])
        expect(s).not_to be_nil
        expect(s.name).to eq(stamp_name)
        expect(s.owner_id).to eq(user)
      end
    end

    context 'when I specify an owner' do
      let(:postdata) do
        {
          type: 'stamps',
          attributes: { name: stamp_name, 'owner-id': 'jeff' },
        }
      end

      it { expect(response).to have_http_status(:bad_request) }

      it 'includes an error' do
        expect(errors).not_to be_empty
        expect(errors.first[:detail]).to match(/owner[_-]id/)
      end

      it 'should not have created the stamp' do
        expect(Stamp.where(name: stamp_name).first).to be_nil
      end
    end
  end

  describe 'POST #set_permissions' do
    let(:permission_data) do
      [
        { 'permission-type': :consume, permitted: 'jeff' },
        { 'permission-type': :edit, permitted: 'jeff' },
        { 'permission-type': :consume, permitted: 'dirk' },
      ]
    end

    let(:deactivate) { false }

    def permission_results
      @stamp.reload.permissions.map do |p|
        {
          'permission-type': p.permission_type.to_sym,
          permitted: p.permitted,
        }
      end
    end

    before do
      if deactivate
        @stamp.deactivate!
      end
      post api_v1_stamp_set_permissions_path(@stamp.id), params: { data: permission_data }.to_json, headers: headers
    end

    context 'when I own the stamp' do
      let(:owner) { user }

      it { expect(response).to have_http_status(:ok) }

      it 'should update the stamp permissions' do
        expect(permission_results).to match_array(permission_data)
      end


      context 'when the stamp is deactivatd' do
        let(:deactivate) { true }
        
        it { expect(response).to have_http_status(:gone) }

        it 'should not update the stamp permissions' do
          expect(permission_results).to match_array([{'permission-type': :consume, permitted: 'pirates'}])
        end
      end
    end

    context 'when I do not own the stamp' do

      it { expect(response).to have_http_status(:forbidden) }

      it 'should not update the stamp permissions' do
        expect(permission_results).to match_array([{'permission-type': :consume, permitted: 'pirates'}])
      end

    end


  end

  describe 'POST #apply' do
    let(:post_materials) { [SecureRandom.uuid] }
    let(:postdata) { { data: { materials: post_materials } } }
    let(:deactivate) { false }

    before do
      request_data = { owner_id: user, materials: post_materials }
      stub_request(:post, "#{Rails.configuration.material_url}/materials/verify_ownership").
        with(body: request_data.to_json).
        to_return(status: ownership_status)
      @init_materials = @stamp.stamp_materials.map(&:material_uuid)
      if deactivate
        @stamp.deactivate!
      end

      if ownership_status == 403
        allow_any_instance_of(Api::V1::StampsController).to receive(:check_deputy).and_return(false)
      end

      post api_v1_stamp_apply_path(@stamp.id), params: postdata.to_json, headers: headers
    end

    def result_materials
      @stamp.reload.stamp_materials.map(&:material_uuid)
    end

    context 'when I own the materials' do
      let(:ownership_status) { 200 }

      it 'should stamp the materials' do
        expect(result_materials).to match_array(@init_materials+post_materials)
      end

      context 'when the stamp is deactivated' do
        let(:deactivate) { true }

        it { expect(response).to have_http_status(:gone) }

        it 'should not stamp the materials' do
          expect(result_materials).to match_array(@init_materials)
        end
      end
    end

    context 'when I do not own the materials' do
      let(:ownership_status) { 403 }

      it { expect(response).to have_http_status(:forbidden) }

      it 'should not stamp the materials' do
        expect(result_materials).to match_array(@init_materials)
      end
    end
  end

  describe 'POST #unapply' do
    let(:deactivate) { false }

    before do
      create(:stamp_material, stamp: @stamp)
      @init_materials = result_materials
      @post_materials = @init_materials[0,1]
      @remaining_materials = @init_materials[1,@init_materials.length]

      request_data = { owner_id: user, materials: @post_materials }
      stub_request(:post, "#{Rails.configuration.material_url}/materials/verify_ownership").
        with(body: request_data.to_json).
        to_return(status: ownership_status)
      postdata = { data: { materials: @post_materials } }
      if deactivate
        @stamp.deactivate!
      end

      if ownership_status == 403
        allow_any_instance_of(Api::V1::StampsController).to receive(:check_deputy).and_return(false)
      end

      post api_v1_stamp_unapply_path(@stamp.id), params: postdata.to_json, headers: headers
    end

    def result_materials
      @stamp.reload.stamp_materials.map(&:material_uuid)
    end

    context 'when I own the materials' do
      let(:ownership_status) { 200 }

      it { expect(response).to have_http_status(:ok) }

      it 'should unstamp the materials' do
        expect(result_materials).to match_array(@remaining_materials)
      end

      context 'when the stamp is deactivated' do
        let(:deactivate) { true }

        it { expect(response).to have_http_status(:gone) }

        it 'should not unstamp the materials' do
          expect(result_materials).to match_array(@init_materials)
        end
      end
    end

    context 'when I do not own the materials' do
      let(:ownership_status) { 403 }

      it { expect(response).to have_http_status(:forbidden) }

      it 'should not unstamp the materials' do
        expect(result_materials).to match_array(@init_materials)
      end
    end
  end

end

