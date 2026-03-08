class AddAuctionFieldsToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :sale_type, :integer, default: 0, null: false
    add_column :items, :start_price, :integer
    add_column :items, :end_at, :datetime
    add_column :items, :min_increment, :integer, default: 100, null: false
  end
end
