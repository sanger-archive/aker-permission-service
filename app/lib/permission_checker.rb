require 'set'

class PermissionChecker

  class << self
    attr_reader :unpermitted_uuids

    def check(permission_type, names, material_uuids)
      material_uuids = material_uuids.uniq
      @unpermitted_uuids = []
      permitted_uuids = Set.new(select_permitted_material_uuids(permission_type, names, material_uuids))

      @unpermitted_uuids = material_uuids.reject { |mu| permitted_uuids.include?(mu) }
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

  end

end
