require 'set'

class PermissionChecker

  class << self
    attr_reader :unpermitted_uuids

    def check(permission_type, names, material_uuids)
      @unpermitted_uuids = []
      stamp_ids = AkerPermissionGem::Permission.select(:accessible_id).where(permission_type: permission_type, permitted: names).distinct.map(&:accessible_id)
      permitted_uuids = Set.new(StampMaterial.select(:material_uuid).where(material_uuid: material_uuids, stamp_id: stamp_ids).map(&:material_uuid))

      @unpermitted_uuids = material_uuids.reject {|mu| permitted_uuids.include?(mu) }
      return @unpermitted_uuids.empty?
    end

  end


end