require 'rails_helper'

RSpec.describe Api::V1::PermissionResource, type: :resource do
  let(:stamp) { create(:stamp) }
  let(:permission) { stamp.permissions.create(permission_type: :stamp, permitted: 'pirates') }

  subject { described_class.new(permission, {}) }

  it { is_expected.to have_primary_key :id }

  it { is_expected.to have_attribute :permission_type }

  it { is_expected.to have_attribute :permitted }

  it { is_expected.to have_one(:stamp).with_class_name('Stamp') }
end
