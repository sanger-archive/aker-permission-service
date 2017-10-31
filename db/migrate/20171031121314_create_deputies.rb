class CreateDeputies < ActiveRecord::Migration[5.0]
  def change
    create_table :deputies, id: :uuid do |t|
      t.string :user_email
      t.string :deputy

      t.timestamps
    end
    add_index :deputies, :deputy
  end
end
