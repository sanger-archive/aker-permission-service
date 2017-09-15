module Api
  module V1
    class MaterialResource < JSONAPI::Resource
      model_name 'StampMaterial'
      attributes :material_uuid, :stamp_id
      filter :material_uuid
      has_one :stamp

      filter :permitted, apply: -> (records, value, _options) {
        records.joins(:stamp => :permissions).where(stamp: { permissions: { permitted: value}})
      }

      filter :permission_type, apply: -> (records, value, _options) {
        records.joins(:stamp => :permissions).where(stamp: { permissions: { permission_type: value}})
      }      

      def self.creatable_fields(context)
        [:material_uuid, :stamp_id]
      end

      def self.updatable_fields(context)
        []
      end

      before_save :authorize!
      before_remove :authorize!

      def authorize!
        user_id = context[:current_user].email
        begin
          MatconClient::Material.verify_ownership(user_id, [material_uuid])
        rescue MatconClient::Errors::ApiError
          raise CanCan::AccessDenied
        end
      end
    end
  end
end
