require 'rails_helper'
require 'pp'

RSpec.describe 'api/v1/permissions', type: :request do
  let(:vnd) { 'application/vnd.api+json' }
  let(:email) { 'me@here.com' }
  let(:groups) { ['world', 'pirates'] }
  let(:owner) { 'owner@here.com' }

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

  describe 'POST #create' do
    before do
      post api_v1_permissions_path, params: { data: postdata }.to_json, headers: headers
    end

    context 'when the request is correct' do
      let(:postdata) do
        {
          type: 'permissions',
          attributes: { 'permission-type': :spend, permitted: 'jeff', 'accessible-id': @stamp.id },
        }
      end

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
  end
  
end

