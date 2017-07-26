require 'aker_permission_gem'

module Api
  module V1
    class PermissionResource < JSONAPI::Resource
      model_name 'AkerPermissionGem::Permission'
      attributes :permission_type, :permitted, :accessible_id
      has_one :stamp, relation_name: 'accessible', foreign_key: :accessible_id

      def self.creatable_fields(context)
        [:permission_type, :permitted, :accessible_id]
      end

      def self.updatable_fields(context)
        []
      end

      before_save :authorize!
      before_remove :authorize!

      def authorize!
        if context[:current_user].email!=@model.accessible.owner_id
          raise CanCan::AccessDenied
        end
      end

      before_create do
        @model.accessible_type = 'Stamp'
      end
    end
  end
end
