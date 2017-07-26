require 'rails_helper'
require 'pp'

RSpec.describe 'api/v1/permissions', type: :request do
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
    @stamps = create_list(:stamp, 2, owner_id: owner)
    @stamp = @stamps.first
    @stamp.permissions.create!(permission_type: :spend, permitted: 'pirates')
    create(:stamp_material, stamp: @stamp)
  end

  describe 'GET #index' do
    before do
      get api_v1_permissions_path, headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'lists all the permissions' do
      expect(data.length).to eq(1)
      d = data.first
      perm = AkerPermissionGem::Permission.first
      expect(d[:id]).to eq(perm.id.to_s)
      atr = d[:attributes]
      expect(atr[:permitted]).to eq(perm.permitted)
      expect(atr[:'permission-type']).to eq(perm.permission_type)
      expect(atr[:'accessible-id']).to eq(perm.accessible_id)
    end
  end

  describe 'GET #show' do
    let(:perm) { @stamp.permissions.first }

    before do
      get api_v1_permission_path(perm.id), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'contains the permission' do
      expect(data[:id]).to eq(perm.id.to_s)
      atr = data[:attributes]
      expect(atr[:'permission-type']).to eq(perm.permission_type)
      expect(atr[:permitted]).to eq(perm.permitted)
      expect(atr[:'accessible-id']).to eq(perm.accessible_id)
    end
  end

  describe 'POST #create' do
    let(:postdata) do
      {
        type: 'permissions',
        attributes: { 'permission-type': :spend, permitted: 'jeff', 'accessible-id': @stamp.id },
      }
    end

    before do
      post api_v1_permissions_path, params: { data: postdata }.to_json, headers: headers
    end

    context 'when I own the stamp' do
      let(:owner) { user }

      it { expect(response).to have_http_status(:created) }

      it 'should contain a created permission' do
        expect(data[:id]).to be_present
        atr = data[:attributes]
        expect(atr[:'permission-type'].to_sym).to eq(:spend)
        expect(atr[:permitted]).to eq('jeff')
        expect(atr[:'accessible-id']).to eq(@stamp.id)
      end

      it 'should add the permission to the stamp' do
        perm = @stamp.permissions.find { |p| p.id.to_s==data[:id] }
        expect(perm).not_to be_nil
        expect(perm.permitted).to eq('jeff')
        expect(perm.permission_type.to_sym).to eq(:spend)
        expect(perm.accessible).to eq(@stamp)
      end

    end

    context 'when I do not own the stamp' do

      it { expect(response).to have_http_status(:forbidden) }

      it 'should not add the permission to the stamp' do
        expect(@stamp.permissions.none? { |p| p.permitted=='jeff' }).to eq(true)
      end

    end
  end

  describe 'DELETE #destroy' do
    let(:perm_id) { @stamp.permissions.first.id }

    before do
      delete api_v1_permission_path(perm_id), headers: headers
    end

    context 'when I own the stamp' do
      let(:owner) { user }

      it { expect(response).to have_http_status(:no_content) }

      it 'should have deleted the permission' do
        expect(@stamp.permissions.none? { |p| p.id==perm_id })
        expect(AkerPermissionGem::Permission.where(id: perm_id).first).to be_nil
      end
    end

    context 'when I do not own the stamp' do
      it { expect(response).to have_http_status(:forbidden) }

      it 'should not have deleted the permission' do
        expect(@stamp.permissions.any? { |p| p.id==perm_id })
        expect(AkerPermissionGem::Permission.where(id: perm_id).first).not_to be_nil
      end
    end

  end
  
end

