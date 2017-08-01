require 'set'

class PermissionChecker

  class << self
    attr_reader :unpermitted_uuids

    def check(permission_type, names, material_uuids)
      @unpermitted_uuids = []
      permitted_uuids = Set.new(
        StampMaterial.where(material_uuid: material_uuids, stamp_id: select_permitted_stamp_ids(permission_type, names)).
                      pluck('distinct material_uuid')
      )

      @unpermitted_uuids = material_uuids.reject { |mu| permitted_uuids.include?(mu) }
      return @unpermitted_uuids.empty?
    end

  private

    def select_permitted_stamp_ids(permission_type, names)
      AkerPermissionGem::Permission.select(:accessible_id).where(permission_type: permission_type, permitted: names).distinct()
    end

  end

end
