class ChangeFieldsToCaseInsensitive < ActiveRecord::Migration[5.0]
  def up
    enable_extension 'citext'

    change_column :deputies, :user_email, :citext, null: false
    change_column :deputies, :deputy, :citext, null: false

    change_column :permissions, :permitted, :citext

    change_column :stamps, :name, :citext
    change_column :stamps, :owner_id, :citext

    Deputy.find_each { |d| d.save! if [d.sanitise_user, d.sanitise_deputy].any? } # Non short-circuiting OR
    AkerPermissionGem::Permission.find_each { |p| p.save! if p.sanitise_permitted }
    Stamp.find_each { |s| s.save! if [s.sanitise_name, s.sanitise_owner].any? } # Non short-circuiting OR
  end

  def down
    change_column :deputies, :user_email, :string, null: true
    change_column :deputies, :deputy, :string, null: true

    change_column :permissions, :permitted, :string

    change_column :stamps, :name, :string
    change_column :stamps, :owner_id, :string
  end
end
