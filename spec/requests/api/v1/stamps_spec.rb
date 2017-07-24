require 'rails_helper'

RSpec.describe 'api/v1/stamps', type: :request do
  let(:vnd) { 'application/vnd.api+json' }
  let(:email) { 'me@here.com' }
  let(:groups) { ['world', 'pirates'] }
  let(:jwt) do
    JWT.encode({ data: { 'email' => email, 'groups' => groups }}, Rails.configuration.jwt_secret_key, 'HS256')
  end
  let(:headers) do
    {
      'Content-Type' => vnd,
      'Accept' => vnd,
      'HTTP_X_AUTHORISATION' => jwt
    }
  end

  let(:data) { JSON.parse(response.body, symbolize_names: true)[:data] }

  before do
    @stamps = create_list(:stamp, 2)
    @stamp = @stamps.first
    @stamp.permissions.create!(permission_type: :spend, permitted: 'pirates')
    create(:stamp_material, stamp: @stamp)
  end

  describe 'INDEX' do
    before do
      get api_v1_stamps_path, headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'should contain the correct number of stamps' do
      expect(data.length).to eq(@stamps.length)
    end

    it 'should have the correct stamp ids' do
      expect(data.pluck(:id)).to match_array(@stamps.map(&:id))
    end
  end

  describe 'GET' do
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

end
