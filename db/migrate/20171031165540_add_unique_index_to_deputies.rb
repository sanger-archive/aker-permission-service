class AddUniqueIndexToDeputies < ActiveRecord::Migration[5.0]
  def change
    add_index :deputies, [:user_email, :deputy], unique: true
  end
end
