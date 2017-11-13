require 'rails_helper'

RSpec.describe Deputy, type: :model do
  describe '#user_email' do
    it 'should be sanitised' do
      expect(create(:deputy, user_email: '  ALPHA@BETA  ').user_email).to eq('alpha@beta')
    end
  end

  describe '#deputy' do
    it 'should be sanitised' do
      expect(create(:deputy, deputy: '  ALPHA@BETA  ').deputy).to eq('alpha@beta')
    end
  end

  describe 'validation' do
    it 'should not be valid unless the sanitised user/deputy combination is unique' do
      create(:deputy, user_email: 'alpha@omega', deputy: 'beta@omega')
      expect(build(:deputy, user_email: '  ALPHA@OMEGA  ', deputy: '  BETA@OMEGA  ')).not_to be_valid
    end
    it 'should be valid if the sanitised user/deputy combination is unique' do
      create(:deputy, user_email: 'boss1@omega', deputy: 'dep1@omega')
      create(:deputy, user_email: 'boss2@omega', deputy: 'dep2@omega')
      
      expect(build(:deputy, user_email: '  BOSS1@OMEGA  ', deputy: '  DEP2@OMEGA  ')).to be_valid
    end
  end
end
