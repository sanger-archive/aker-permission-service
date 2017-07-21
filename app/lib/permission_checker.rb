require 'set'

class PermissionChecker

  class << self
    attr_reader :unpermitted_uuids

    def check(permission_type, names, material_uuids)
      @unpermitted_uuids = []
      stamp_ids = AkerPermissionGem::Permission.where(permission_type: permission_type, permitted: names).pluck('distinct accessible_id')
      permitted_uuids = Set.new(StampMaterial.where(material_uuid: material_uuids, stamp_id: stamp_ids).pluck('distinct material_uuid'))

      @unpermitted_uuids = material_uuids.reject {|mu| permitted_uuids.include?(mu) }
      return @unpermitted_uuids.empty?
    end

  end


end