module Api
  module V1
    class StampResource < JSONAPI::Resource
      attributes :name, :owner_id
      key_type :uuid
      has_many :permissions, class_name: 'Permission', relation_name: :permissions
      has_many :materials, class_name: 'Material', relation_name: :stamp_materials

      filter :activeness, default: "true", apply: -> (records, value, _options) {
        (value[0].downcase == "true") ? records.where(deactivated_at: nil) : records.where.not(deactivated_at: nil)
      }

      def self.updatable_fields(context)
        [:name]
      end
      def self.creatable_fields(context)
        [:name]
      end

      before_create do
        @model.owner_id = context[:current_user].email
      end

      before_update :authorize!

      def remove
        authorize!
        @model.deactivate!
        :completed
      end

      def authorize!
        if @model.deactivated?
          raise Errors::ResourceGone
        end
        if @model.owner_id != context[:current_user].email
          raise CanCan::AccessDenied
        end
      end
    end
  end
end
