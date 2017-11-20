FactoryBot.define do
  factory :permission, class: AkerPermissionGem::Permission do
    permitted "user@sanger.ac.uk"
    permission_type :spend
    accessible_type "Stamp"
  end
end
