module Api
  module V1
    class StampResource < JSONAPI::Resource
      attributes :name, :owner_id
      key_type :uuid
      has_many :permissions, class_name: 'Permission', relation_name: :permissions
      has_many :materials, class_name: 'Material', relation_name: :stamp_materials

      # http://localhost:3000/api/v1/sets?filter[owner_id]=guest
      filter :owner_id, apply: -> (records, value, _options) {
        return records.none if value.nil?
        records.where(owner_id: value)
      }

      before_create do
        @model.owner_id = context[:current_user].email
      end

      def self.updatable_fields(context)
        [:name]
      end
      def self.creatable_fields(context)
        [:name]
      end

      before_update :authorize!
      before_remove :authorize!

      def authorize!
        if @model.owner_id != context[:current_user].email
          raise CanCan::AccessDenied
        end
      end
    end
  end
end
