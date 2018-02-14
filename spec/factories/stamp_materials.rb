require 'securerandom'

FactoryBot.define do
  factory :stamp_material do
    sequence(:material_uuid) { SecureRandom.uuid }
    stamp
  end
end
