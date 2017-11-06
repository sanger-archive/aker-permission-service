require 'rails_helper'

RSpec.describe 'api/v1/deputies', type: :request do
  let(:vnd) { 'application/vnd.api+json' }
  let(:boss) { 'boss@sanger.ac.uk' }
  let(:groups) { ['world', 'pirates'] }

  let(:jwt) do
    JWT.encode({ data: { 'email' => boss, 'groups' => groups }}, Rails.configuration.jwt_secret_key, 'HS256')
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
    @deputies_list = create_list(:deputy, 3, user_email: boss)
  end

  describe 'GET #index' do
    before do
      get api_v1_deputies_path, headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'should contain the correct number of deputies' do
      expect(data.length).to eq(@deputies_list.length)
    end
  end

  describe 'GET #show' do
    let(:deputy) { @deputies_list.first }
    before do
      get api_v1_deputy_path(deputy), headers: headers
    end

    it { expect(response).to have_http_status(:ok) }

    it 'has the deputy id' do
      expect(data[:id]).to eq(deputy.id)
    end
    it 'has the correct attributes' do
      expect(data[:attributes][:"user-email"]).to eq(deputy.user_email)
      expect(data[:attributes][:deputy]).to eq(deputy.deputy)
    end
  end

  describe 'DELETE #remove' do
    context 'when I am the owner of the deputy assignment' do
      # This should be done using the boss JWT, as they own the deputies
      let(:deputy_to_delete) { @deputies_list.first }

      before do
        delete api_v1_deputy_path(deputy_to_delete), headers: headers
      end

      it { expect(response).to have_http_status(:no_content) }

      it 'removes the deputy record' do
        expect { Deputy.find(deputy_to_delete) }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context 'when I do not own the deputy record' do
      let(:boss_as_deputy) { create(:deputy, user_email: "notboss@sanger.ac.uk", deputy: boss) }

      before do
        delete api_v1_deputy_path(boss_as_deputy), headers: headers
      end

      it { expect(response).to have_http_status(:forbidden) }

      it 'does not remove the deputy record' do
        expect { Deputy.find(boss_as_deputy.id) }.to_not raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST #create' do
    let(:deputy) { "deputy@sanger.ac.uk" }
    before do
      post api_v1_deputies_path, params: { data: postdata }.to_json, headers: headers
    end

    context 'when the request is correct' do
      let(:postdata) do
        {
          type: 'deputies',
          attributes: { "user-email": boss, deputy: deputy },
        }
      end

      it { expect(response).to have_http_status(:created) }

      it 'should include the deputy in the response' do
        expect(data[:id]).not_to be_nil
        atr = data[:attributes]
        expect(atr[:"user-email"]).to eq(boss)
        expect(atr[:deputy]).to eq(deputy)
      end

      it 'should have created the deputy record' do
        deputy_record = Deputy.find(data[:id])
        expect(deputy_record).not_to be_nil
        expect(deputy_record.user_email).to eq(boss)
        expect(deputy_record.deputy).to eq(deputy)
      end
    end
  end

end
