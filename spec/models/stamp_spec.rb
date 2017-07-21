require 'rails_helper'

RSpec.describe Stamp, type: :model do

  describe 'validation' do
    it 'is not valid without a name' do
      expect(build(:stamp, name: nil)).not_to be_valid
    end

    it 'is not valid without a unique name' do
      stamp = create(:stamp)
      expect(build(:stamp, name: stamp.name)).not_to be_valid
    end

    it 'is not valid without an owner_id' do
      expect(build(:stamp, owner_id: nil)).not_to be_valid
    end
  end
end
