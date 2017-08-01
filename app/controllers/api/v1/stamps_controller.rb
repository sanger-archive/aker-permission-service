require 'set'

module Api
  module V1
    class StampsController < ApiController

      def set_permissions
        stamp = current_stamp
        if context[:current_user].email!=stamp.owner_id
          raise CanCan::AccessDenied
        end
        sp = set_permissions_params
        ActiveRecord::Base.transaction do |t|
          stamp.permissions.destroy_all
          stamp.permissions.create!(sp)
        end
        jsondata = JSONAPI::ResourceSerializer.new(Api::V1::StampResource, include: ['permissions']).serialize_to_hash(Api::V1::StampResource.new(stamp, nil))
        render json: jsondata, status: :ok, content_type: 'application/vnd.api+json'
      end

      def apply
        stamp = current_stamp
        materials = apply_params
        authorize_materials(materials)
        current_materials_set = Set.new(stamp.stamp_materials.map(&:material_uuid))
        materials.reject! { |m| current_materials_set.include?(m) }
        unless materials.empty?
          ActiveRecord::Base.transaction do
            StampMaterial.create!(materials.map { |m| { stamp: stamp, material_uuid: m } })
          end
        end
        render_apply_response(stamp)
      end

      def unapply
        stamp = current_stamp
        materials = apply_params
        authorize_materials(materials)
        current_materials_set = Set.new(stamp.stamp_materials.map(&:material_uuid))
        materials.select! { |m| current_materials_set.include?(m) }
        unless materials.empty?
          ActiveRecord::Base.transaction do
            StampMaterial.where(stamp_id: stamp.id, material_uuid: materials).destroy_all
          end
        end
        render_apply_response(stamp)
      end

    private

      def current_stamp
        Stamp.find(params[:stamp_id])
      end

      def authorize_materials(materials)
        user_id = context[:current_user].email
        begin
          MatconClient::Material.verify_ownership(user_id, materials)
        rescue MatconClient::Errors::ApiError
          raise CanCan::AccessDenied
        end
      end

      def set_permissions_params
        return [] unless params[:data].present?
        params.require(:data).map do |d|
          {
            permission_type: d.require(:'permission-type'),
            permitted: d.require(:permitted),
          }
        end
      end

      def apply_params
        params.require(:data).require(:materials)
      end

      def render_apply_response(stamp)
        jsondata = JSONAPI::ResourceSerializer.new(Api::V1::StampResource, include: ['materials']).serialize_to_hash(Api::V1::StampResource.new(stamp, nil))
        render json: jsondata, status: :ok, content_type: 'application/vnd.api+json'
      end
    end
  end
end
