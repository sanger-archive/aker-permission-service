require 'aker_permission_gem'

module Api
  module V1
    class PermissionResource < JSONAPI::Resource
      model_name 'AkerPermissionGem::Permission'
      attributes :permission_type, :permitted
      has_one :stamp, relation_name: 'accessible', foreign_key: :accessible_id
    end
  end
end
