module Api
  module V1
    class PermissionsController < ApiController
      def check
        data = check_params
        ok = PermissionChecker.check(data[:permission_type], data[:names], data[:material_uuids])
        if ok
          head :ok, content_type: 'application/json'
        else
          failed_material_uuids = PermissionChecker.unpermitted_uuids
          render json: { errors: [ {status: '403', title: 'Permission failed', detail: 'The specified permission was not present for some materials.', material_uuids: failed_material_uuids }] }, status: :forbidden
        end
      end

    private
      def check_params
        d = params.require(:data)
        [:permission_type, :names, :material_uuids].each { |f| d.require(f) }
        d.permit(:permission_type, names: [], material_uuids: [])
      end
    end
  end
end
