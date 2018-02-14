require 'rails_helper'

RSpec.describe AkerPermissionGem::Permission, type: :model do
  let(:stamp) { create(:stamp) }
  describe '#permission' do
    it 'should be sanitised' do
      perm = create(:permission, permitted: '  ALPHA@BETA  ', accessible_id: stamp.id)
      expect(perm.permitted).to eq('alpha@beta')
    end
  end
end
