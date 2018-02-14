class UpdateNameIndexForStamps < ActiveRecord::Migration[5.0]
  def change
    remove_index(:stamps, :name => 'index_stamps_on_name')
    add_index :stamps, :name
  end
end
