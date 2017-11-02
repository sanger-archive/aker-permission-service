FactoryBot.define do
  factory :deputy do
    user_email "boss@sanger.ac.uk"
    sequence :deputy do |n|
      "deputy#{n}@sanger.ac.uk"
    end
  end
end
