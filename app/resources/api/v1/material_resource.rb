module Api
  module V1
    class MaterialResource < JSONAPI::Resource
      immutable

      model_name 'StampMaterial'
      attributes :material_uuid
      has_one :stamp

      def self.updatable_fields(context)
        []
      end
    end
  end
end
