class CreateStamps < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')

    create_table :stamps, id: :uuid do |t|
      t.string :name, null: false
      t.string :owner_id, null: false

      t.timestamps
    end
    add_index :stamps, :name, unique: true
  end
end
