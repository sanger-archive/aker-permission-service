module Api
  module V1
    class StampsController < ApiController

      def set_permissions
        stamp = Stamp.find(params[:stamp_id])
        if context[:current_user].email!=stamp.owner_id
          raise CanCan::AccessDenied
        end
        sp = set_permissions_params
        ActiveRecord::Base.transaction do |t|
          stamp.permissions.destroy_all
          stamp.permissions.create!(sp)
        end
        jsondata = JSONAPI::ResourceSerializer.new(Api::V1::StampResource, include: ['permissions']).serialize_to_hash(Api::V1::StampResource.new(stamp, nil))
        render json: jsondata, status: :created, content_type: 'application/vnd.api+json'
      end

    private

      def set_permissions_params
        return [] unless params[:data].present?
        params.require(:data).map do |d|
          {
            permission_type: d.require(:'permission-type'),
            permitted: d.require(:permitted),
          }
        end
      end
    end
  end
end
