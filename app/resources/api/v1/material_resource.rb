module Api
  module V1
    class MaterialResource < JSONAPI::Resource
      model_name 'StampMaterial'
      attributes :material_uuid
      has_one :stamp
    end
  end
end
