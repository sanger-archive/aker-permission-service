module Api
  module V1
    class StampResource < JSONAPI::Resource
      attributes :name, :owner_id
      key_type :uuid
      has_many :permissions, class_name: 'Permission', relation_name: :permissions
      has_many :materials, class_name: 'Material', relation_name: :stamp_materials

      before_create do
        @model.owner_id = context[:current_user].email
      end

      def self.updatable_fields(context)
        [:name]
      end
      def self.creatable_fields(context)
        [:name]
      end

      before_update do
        if @model.owner_id != context[:current_user].email
          raise CanCan::AccessDenied
        end
      end

      before_remove do
        if @model.owner_id != context[:current_user].email
          raise CanCan::AccessDenied
        end
      end
    end
  end
end
