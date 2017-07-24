class CreateStampMaterials < ActiveRecord::Migration[5.0]
  def change
    create_table :stamp_materials do |t|
      t.uuid :material_uuid, null: false
      t.references :stamp, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end
    add_index :stamp_materials, :material_uuid
    add_index :stamp_materials, [:material_uuid, :stamp_id], unique: true
  end
end
