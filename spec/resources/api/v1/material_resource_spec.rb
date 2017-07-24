require 'rails_helper'

RSpec.describe Api::V1::MaterialResource, type: :resource do
  let(:stamp_material) { create(:stamp_material) }

  subject { described_class.new(stamp_material, {}) }

  it { is_expected.to have_primary_key :id }

  it { is_expected.to have_attribute :material_uuid }

  it { is_expected.to have_one(:stamp).with_class_name('Stamp') }
end