require 'rails_helper'

RSpec.describe Api::V1::PermissionsController, type: :controller do
  before do
    stub_request(:post, Rails.application.config.material_url+'/materials/search').
      to_return(status: 200, body: {_items: []}.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#check' do
    before do
      stamp = create(:stamp)
      sm = create(:stamp_material, stamp: stamp)
      @material_uuid = sm.material_uuid
      stamp.permissions.create!(permission_type: :consume, permitted: 'mygroup')
    end

    context 'when the materials are permitted' do
      before do
        post :check, params: { data: { permission_type: :consume, names: ['dirk', 'mygroup'], material_uuids: [@material_uuid] }  }
      end
      it 'responds OK' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when some materials are not permitted' do
      before do
        @bad_uuid = SecureRandom.uuid
        post :check, params: { data: { permission_type: :consume, names: ['dirk', 'mygroup'], material_uuids: [@material_uuid, @bad_uuid] }  }
      end
      it 'responds forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
      it 'lists the failing material uuids' do
        errors = JSON.parse(response.body)['errors']
        expect(errors.length).to eq(1)
        expect(errors.first['material_uuids']).to eq([@bad_uuid])
      end
    end
  end
end
