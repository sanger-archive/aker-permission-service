require 'securerandom'

FactoryGirl.define do
  factory :stamp_material do
    sequence(:material_uuid) { SecureRandom.uuid }
    stamp
  end
end
