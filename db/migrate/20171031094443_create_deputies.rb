class CreateDeputies < ActiveRecord::Migration[5.0]
  def change
    create_table :deputies, id: :uuid do |t|
      t.string :user_email, null: false
      t.string :deputy, null: false # Either a user email or LDAP group
    end

    add_index :deputies, :deputy

  end
end
