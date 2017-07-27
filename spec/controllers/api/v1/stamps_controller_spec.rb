require 'rails_helper'
require 'ostruct'

RSpec.describe Api::V1::StampsController, type: :controller do
  let(:vnd) { 'application/vnd.api+json' }
  let(:user) { 'me@here.com' }
  let(:owner) { user }

  let(:current_user) do
    OpenStruct.new(email: user, groups: ['world'])
  end

  describe '#set_permissions' do
    let(:stamp) do
      s = create(:stamp, owner_id: owner)
      s.permissions.create!(init_permissions) if init_permissions.present?
      s
    end

    let(:init_permissions) do
      [
        { permission_type: :spend, permitted: 'alpha' },
        { permission_type: :write, permitted: 'beta' },
      ]
    end

    let(:permission_data) do
      [
        { 'permission-type': :spend, permitted: 'omega' }
      ]
    end

    def jsonify(permission)
      { 'permission-type': permission.permission_type.to_sym, permitted: permission.permitted }
    end

    def result_permissions
      stamp.reload.permissions.map do |permission|
        { 'permission-type': permission.permission_type.to_sym, permitted: permission.permitted }
      end
    end

    before do
      allow_any_instance_of(Api::V1::StampsController).to receive(:current_user).and_return(current_user)
      post :set_permissions, params: { data: permission_data, stamp_id: stamp.id }
    end

    context 'when stamp is owned by the user' do
      context 'when permissions are replaced' do
        it { expect(response).to have_http_status(:created) }

        it 'replaces the stamp permissions' do
          expect(result_permissions).to match_array(permission_data)
        end
      end

      context 'when permissions are removed without adding new ones' do
        let(:permission_data) { [] }

        it { expect(response).to have_http_status(:created) }

        it 'clears the stamp permissions' do
          expect(result_permissions).to be_empty
        end
      end

      context 'when permissions are added to a stamp that had none' do
        let(:init_permissions) { [] }

        it { expect(response).to have_http_status(:created) }

        it 'sets the new stamp permissions' do
          expect(result_permissions).to match_array(permission_data)
        end
      end
    end

    context 'when stamp is not owned by the user' do
      let(:owner) { 'someone_else' }

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not update the stamp permissions' do
        initial_permissions = [
          { 'permission-type': :spend, permitted: 'alpha' },
          { 'permission-type': :write, permitted: 'beta' },
        ]
        expect(result_permissions).to match_array(initial_permissions)
      end
    end

  end
end
