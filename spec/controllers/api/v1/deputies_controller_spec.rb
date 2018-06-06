require 'rails_helper'

RSpec.describe Api::V1::DeputiesController, type: :controller do
  let(:email) { "tester@sanger.ac.uk" }

  before do
    @jwt = JWT.encode({ data: { 'email' => email, 'groups' => ['world'] } }, Rails.configuration.jwt_secret_key, 'HS256')
    request.headers["HTTP_X_AUTHORISATION"] = @jwt
    request.headers['Content-Type'] = 'application/vnd.api+json'
  end

  describe '#create' do
    context 'when creating a valid deputy' do
      before do
        post :create, params: { data:
          { type: :deputies, attributes: { deputy: "ac42@sanger.ac.uk" } } }
      end

      it 'responds CREATED' do
        expect(response).to have_http_status(:created)
      end
    end

    context 'when creating a deputy that already exists' do
      before do
        create(:deputy, user_email: email, deputy: "user@sanger.ac.uk")
      end

      it 'prevents this with error 422' do
        post :create, params: { data:
          { type: :deputies, attributes: { deputy: "user@sanger.ac.uk" } } }
        expect(response).to have_http_status(422)
      end
    end

    context 'when attempting to deputise oneself' do
      before do
        post :create, params: { data:
          { type: :deputies, attributes: { deputy: email } } }
      end

      it 'prevents this with error 422' do
        expect(response).to have_http_status(422)
      end
    end
  end
end
