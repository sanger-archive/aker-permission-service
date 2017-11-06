module Api
  module V1
    class DeputyResource < JSONAPI::Resource
      attributes :user_email, :deputy
      key_type :uuid

      def self.updatable_fields(context)
        []
      end
      def self.creatable_fields(context)
        [:user_email, :deputy]
      end

      before_create do
        @model.user_email = context[:current_user].email
      end

      before_update :authorize!

      def remove
        authorize!
        @model.delete
        :completed
      end

      def authorize!
        if @model.user_email != context[:current_user].email
          raise CanCan::AccessDenied
        end
      end
    end
  end
end
