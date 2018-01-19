class PermissionChecker
  class << self
    attr_reader :unpermitted_uuids

    # Returns a boolean to indicate whether 'names' (consisting of a Sanger user
    # and their LDAP groups) have the 'permission_type' on the materials
    # represented by the IDs in 'material_uuids'
    # As long as the user or any of the groups have the 'permission_type' over
    # all of the materials, this will return true. False otherwise.
    def check(permission_type, names, material_uuids)
      material_uuids = material_uuids.uniq
      @unpermitted_uuids = []
      permitted_uuids = select_permitted_material_uuids(permission_type, names,
                                                        material_uuids)
      @unpermitted_uuids = material_uuids - permitted_uuids
      @unpermitted_uuids -= owned_material_uuids(@unpermitted_uuids, names)
      @unpermitted_uuids -= deputised_material_uuids(@unpermitted_uuids, names)
      return @unpermitted_uuids.empty?
    end

    private

    def select_permitted_material_uuids(permission_type, names, material_uuids)
      AkerPermissionGem::Permission
        .joins('JOIN stamps ON (accessible_id=stamps.id)')
        .joins('JOIN stamp_materials ON (stamps.id=stamp_materials.stamp_id)')
        .where(stamps: { deactivated_at: nil },
               permissions: { permitted: names,
                              permission_type: permission_type },
               stamp_materials: { material_uuid: material_uuids })
        .pluck('distinct material_uuid')
    end

    # Returns an array of material IDs that the user is authorised to 'consume'
    # (order work on) as they are the owner (Sample Guardian) of that material
    def owned_material_uuids(material_uuids, names)
      puts MatconClient::Material.where(
        _id: { '$in' => material_uuids },
        owner_id: { '$in' => names }
      ).select(:_id).map(&:_id)
    end

    # Returns an array of material IDs that the user is authorised to 'consume'
    # (order work on) by being a deputy of the material Sample Guardian
    def deputised_material_uuids(material_uuids, names)
      # Get materials that need checking for user consume permission
      materials = MatconClient::Material.where(_id: { '$in' => material_uuids })
                                        .map do |material|
                                          [material._id, material.owner_id]
                                        end
      return [] if materials.empty?
      # Extract Sample Guardian email addresses
      sample_guardian_emails = materials.collect { |mat| mat[1] }.uniq
      # Get the Sample Guardian emails that the user is a deputy of
      user_deputy_of = Deputy.where(user_email: sample_guardian_emails,
                                    deputy: names).pluck(:user_email)
      # Remove materials that the user isn't authorised to order work on
      user_unauthorised_for = sample_guardian_emails - user_deputy_of
      materials.delete_if { |mat| user_unauthorised_for.include?(mat[1]) }
               .collect { |mat| mat[0] }
    end
  end
end
