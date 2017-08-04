class AddDeactivatedAtToStamps < ActiveRecord::Migration[5.0]
  def change
    add_column :stamps, :deactivated_at, :datetime
  end
end
