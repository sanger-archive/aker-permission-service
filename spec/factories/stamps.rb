FactoryGirl.define do
  factory :stamp do
    sequence(:name) { |n| "Stamp #{n}" }
    owner_id "jb12"
  end
end
