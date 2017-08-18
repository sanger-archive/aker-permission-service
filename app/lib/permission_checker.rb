class PermissionChecker

  class << self
    attr_reader :unpermitted_uuids

    def check(permission_type, names, material_uuids)
      material_uuids = material_uuids.uniq
      @unpermitted_uuids = []
      permitted_uuids = select_permitted_material_uuids(permission_type, names, material_uuids)

      @unpermitted_uuids = material_uuids - permitted_uuids
      @unpermitted_uuids -= owned_material_uuids(@unpermitted_uuids, names)
      return @unpermitted_uuids.empty?
    end

  private

    def select_permitted_material_uuids(permission_type, names, material_uuids)
      AkerPermissionGem::Permission.
        joins('JOIN stamps ON (accessible_id=stamps.id)').
        joins('JOIN stamp_materials ON (stamps.id=stamp_materials.stamp_id)').
        where(stamps: { deactivated_at: nil },
              permissions: { permitted: names, permission_type: permission_type },
              stamp_materials: { material_uuid: material_uuids }).
        pluck('distinct material_uuid')
    end

    def owned_material_uuids(material_uuids, names)
      MatconClient::Material.where(
        _id: {"$in" => material_uuids},
        owner_id: {"$in" => names}
      ).select(:_id).map { |m| m._id }
    end

  end

end
