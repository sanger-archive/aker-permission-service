require 'rails_helper'

RSpec.describe Api::V1::StampResource, type: :resource do
  let(:stamp) { create(:stamp) }

  subject { described_class.new(stamp, {}) }

  it { is_expected.to have_primary_key :id }

  it { is_expected.to have_attribute :name }

  it { is_expected.to have_attribute :owner_id }

  it { is_expected.to have_many(:permissions).with_class_name('Permission') }

  it { is_expected.to have_many(:materials).with_class_name('Material') }

end