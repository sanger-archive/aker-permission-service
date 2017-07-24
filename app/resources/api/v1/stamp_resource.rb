module Api
  module V1
    class StampResource < JSONAPI::Resource
      attributes :name, :owner_id
      key_type :uuid
      has_many :permissions, class_name: 'Permission', relation_name: :permissions
      has_many :materials, class_name: 'Material', relation_name: :stamp_materials
    end
  end
end
