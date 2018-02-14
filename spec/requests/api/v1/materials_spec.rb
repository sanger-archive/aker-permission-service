require 'rails_helper'
require 'pp'

RSpec.describe 'api/v1/materials', type: :request do
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

  let(:mat_uuid) { SecureRandom.uuid }
  let(:ownership_status) { 200 }

  before do
    @stamps = create_list(:stamp, 2, owner_id: owner)
    @stamp = @stamps.first
    @stamp.permissions.create!(permission_type: :consume, permitted: 'pirates')
    @mat = create(:stamp_material, stamp: @stamp)

    request_data = { owner_id: user, materials: [mat_uuid] }
    stub_request(:post, "#{Rails.configuration.material_url}/materials/verify_ownership").
         with(body: request_data.to_json).
         to_return(status: ownership_status)
  end

  describe 'GET #index' do
    before do
      get api_v1_materials_path, headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'lists all the materials' do
      expect(data.length).to eq(1)
      d = data.first
      expect(d[:id]).to eq(@mat.id.to_s)
      atr = d[:attributes]
      expect(atr[:'stamp-id']).to eq(@mat.stamp_id)
      expect(atr[:'material-uuid']).to eq(@mat.material_uuid)
    end
  end

  describe 'GET #show' do
    before do
      get api_v1_material_path(@mat.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the material' do
      expect(data[:id]).to eq(@mat.id.to_s)
      atr = data[:attributes]
      expect(atr[:'stamp-id']).to eq(@mat.stamp_id)
      expect(atr[:'material-uuid']).to eq(@mat.material_uuid)
    end
  end

  describe 'GET stamp' do
    before do
      get api_v1_material_stamp_path(@mat.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the stamp' do
      expect(data[:id]).to eq(@stamp.id)
      atr = data[:attributes]
      expect(atr[:name]).to eq(@stamp.name)
    end
  end

  describe 'POST #create' do
    before do
      postdata = {
        type: 'materials',
        attributes: { 'stamp-id': @stamp.id, 'material-uuid': mat_uuid }
      }
      post api_v1_materials_path, params: { data: postdata }.to_json, headers: headers
    end

    context 'when I own the material' do
      it { expect(response).to have_http_status(:created) }

      it 'returns the new stamp material' do
        expect(data[:id]).not_to be_nil
        atr = data[:attributes]
        expect(atr[:'stamp-id']).to eq(@stamp.id)
        expect(atr[:'material-uuid']).to eq(mat_uuid)
      end

      it 'adds the material to the stamp' do
        mat = @stamp.stamp_materials.find {|m| m.material_uuid==mat_uuid }
        expect(mat).not_to be_nil
        expect(mat.id.to_s).to eq(data[:id])
        expect(mat.material_uuid).to eq(mat_uuid)
        expect(mat.stamp_id).to eq(@stamp.id)
      end
    end

    context 'when I do not own the material' do
      let(:ownership_status) { 403 }

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not create the stamp material' do
        expect(StampMaterial.where(material_uuid: mat_uuid).first).to be_nil
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:material) { create(:stamp_material, stamp: @stamp, material_uuid: mat_uuid) }

    before do
      delete api_v1_material_path(material.id), headers: headers
    end

    context 'when I own the material' do
      it { expect(response).to have_http_status(:no_content) }

      it 'deletes the stamp material' do
        expect(StampMaterial.where(material_uuid: mat_uuid).first).to be_nil
        expect(StampMaterial.where(id: material.id).first).to be_nil
        expect(@stamp.stamp_materials.find { |m| m.material_uuid==mat_uuid }).to be_nil
      end
    end

    context 'when I do not own the material' do
      let(:ownership_status) { 403 }

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not delete the stamp material' do
        m = StampMaterial.find(material.id)
        expect(m.material_uuid).to eq(mat_uuid)
        expect(m.stamp).to eq(@stamp)
      end
    end
  end


  describe 'PUT #update' do
    let(:owner) { user }

    it 'does not succeed' do
      correct_uuid = @mat.material_uuid
      putdata = { id: @mat.id, type: 'materials', attributes: { 'material-uuid': SecureRandom.uuid, 'stamp-id': @stamp.id }}
      expect { put api_v1_material_path(@mat.id), params: { data: putdata }.to_json, headers: headers }.to raise_error(ActionController::RoutingError)
      expect(@stamp.stamp_materials.first.reload.material_uuid).to eq(correct_uuid)
    end
  end

  describe 'PATCH #update' do
    let(:owner) { user }

    it 'does not succeed' do
      correct_uuid = @mat.material_uuid
      patchdata = { id: @mat.id, type: 'materials', attributes: { 'material-uuid': SecureRandom.uuid }}
      expect { patch api_v1_material_path(@mat.id), params: { data: patchdata }.to_json, headers: headers }.to raise_error(ActionController::RoutingError)
      expect(@stamp.stamp_materials.first.reload.material_uuid).to eq(correct_uuid)
    end
  end
end

