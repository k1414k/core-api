class ChangeUsersDefaultPoints < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :points, from: 0, to: 100000
  end
end
