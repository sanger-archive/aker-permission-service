require 'rails_helper'
require 'ostruct'

RSpec.describe Api::V1::StampsController, type: :controller do
  let(:vnd) { 'application/vnd.api+json' }
  let(:user) { 'me@here.com' }
  let(:owner) { user }
  let(:jwt) { JWT.encode({ data: { 'email' => user, 'groups' => ['world'] } }, Rails.configuration.jwt_secret_key, 'HS256') }

  let(:current_user) do
    OpenStruct.new(email: user, groups: ['world'])
  end

  before do
    request.headers["HTTP_X_AUTHORISATION"] = jwt
    allow_any_instance_of(Api::V1::StampsController).to receive(:current_user).and_return(current_user)
  end

  describe '#set_permissions' do
    let(:stamp) do
      s = create(:stamp, owner_id: owner)
      s.permissions.create!(init_permissions) if init_permissions.present?
      s
    end

    let(:init_permissions) do
      [
        { permission_type: :consume, permitted: 'alpha' },
        { permission_type: :edit, permitted: 'beta' },
      ]
    end

    let(:permission_data) do
      [
        { 'permission-type': :consume, permitted: 'omega' }
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
      post :set_permissions, params: { data: permission_data, stamp_id: stamp.id }
    end

    context 'when stamp is owned by the user' do
      context 'when permissions are replaced' do
        it { expect(response).to have_http_status(:ok) }

        it 'replaces the stamp permissions' do
          expect(result_permissions).to match_array(permission_data)
        end
      end

      context 'when permissions are removed without adding new ones' do
        let(:permission_data) { [] }

        it { expect(response).to have_http_status(:ok) }

        it 'clears the stamp permissions' do
          expect(result_permissions).to be_empty
        end
      end

      context 'when permissions are added to a stamp that had none' do
        let(:init_permissions) { [] }

        it { expect(response).to have_http_status(:ok) }

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
          { 'permission-type': :consume, permitted: 'alpha' },
          { 'permission-type': :edit, permitted: 'beta' },
        ]
        expect(result_permissions).to match_array(initial_permissions)
      end
    end

  end

  describe '#apply' do
    let(:owner) { 'someone_else' } # I do not need to own the stamp
    let(:stamp) do
      s = create(:stamp, owner_id: owner)
      if init_materials.present?
        init_materials.each { |mu| create(:stamp_material, stamp: s, material_uuid: mu) }
      end
      s
    end
    let(:init_materials) { [SecureRandom.uuid] }
    let(:post_materials) { [SecureRandom.uuid, SecureRandom.uuid] }

    def result_materials
      stamp.reload.stamp_materials.map(&:material_uuid)
    end

    before do
      if material_authorised
        allow(MatconClient::Material).to receive(:verify_ownership).with(user, post_materials).and_return(nil)
      else
        allow(MatconClient::Material).to receive(:verify_ownership).with(user, post_materials).and_raise(MatconClient::Errors::AccessDenied, nil)
      end
      post :apply, params: { data: { materials: post_materials }, stamp_id: stamp.id }
    end

    context 'when the material is authorised' do
      let(:material_authorised) { true }

      context 'when the stamp has no materials initially' do
        let(:init_materials) { [] }
        it { expect(response).to have_http_status(:ok) }

        it 'links the materials to the stamp' do
          expect(result_materials).to match_array(post_materials)
        end
      end

      context 'when the stamp has materials already' do
        it { expect(response).to have_http_status(:ok) }

        it 'links the materials to the stamp' do
          expect(result_materials).to match_array(init_materials + post_materials)
        end
      end

      context 'when the init materials and post materials overlap' do
        it { expect(response).to have_http_status(:ok) }

        let(:init_materials) { [SecureRandom.uuid, post_materials.first] }

        it 'links the materials to the stamp' do
          expect(result_materials).to match_array(init_materials + post_materials[1, post_materials.length])
        end
      end

      context 'when all the post materials are already linked to the stamp' do
        it { expect(response).to have_http_status(:ok) }

        let(:init_materials) { [SecureRandom.uuid]+post_materials }

        it 'links the materials to the stamp' do
          expect(result_materials).to match_array(init_materials)
        end
      end
    end

    context 'when the material is not authorised' do
      let(:material_authorised) { false }
      it { expect(response).to have_http_status(:forbidden) }

      it 'does not change the materials for the stamp' do
        expect(result_materials).to match_array(init_materials)
      end
    end

  end

  describe '#unapply' do
    let(:owner) { 'someone_else' } # I do not need to own the stamp
    let(:stamp) do
      s = create(:stamp, owner_id: owner)
      if init_materials.present?
        init_materials.each { |mu| create(:stamp_material, stamp: s, material_uuid: mu) }
      end
      s
    end
    let(:init_materials) { [SecureRandom.uuid, SecureRandom.uuid, SecureRandom.uuid] }
    let(:post_materials) { init_materials[0,2]+[SecureRandom.uuid] }

    def result_materials
      stamp.reload.stamp_materials.map(&:material_uuid)
    end

    before do
      if material_authorised
        allow(MatconClient::Material).to receive(:verify_ownership).with(user, post_materials).and_return(nil)
      else
        allow(MatconClient::Material).to receive(:verify_ownership).with(user, post_materials).and_raise(MatconClient::Errors::AccessDenied, nil)
      end
      post :unapply, params: { data: { materials: post_materials }, stamp_id: stamp.id }
    end

    context 'when the material is authorised' do
      let(:material_authorised) { true }

      context 'when the stamp has no materials initially' do
        let(:init_materials) { [] }
        it { expect(response).to have_http_status(:ok) }

        it 'does not alter the stamp materials' do
          expect(result_materials).to be_empty
        end
      end

      context 'when all materials get unstamped' do
        let(:post_materials) { init_materials + [SecureRandom.uuid] }

        it { expect(response).to have_http_status(:ok) }

        it 'removes all materials' do
          expect(result_materials).to be_empty
        end
      end

      context 'when some materials get unstamped' do
        it { expect(response).to have_http_status(:ok) }

        it 'removes the correct materials' do
          expect(result_materials).to match_array(init_materials[2, init_materials.length])
        end
      end

      context 'when none of the specified materials are linked to the stamp' do
        it { expect(response).to have_http_status(:ok) }

        let(:post_materials) { [SecureRandom.uuid, SecureRandom.uuid] }

        it 'does not remove any materials from the stamp' do
          expect(result_materials).to match_array(init_materials)
        end
      end
    end

    context 'when the material is not authorised' do
      let(:material_authorised) { false }
      it { expect(response).to have_http_status(:forbidden) }

      it 'does not change the materials for the stamp' do
        expect(result_materials).to match_array(init_materials)
      end
    end

  end
end
