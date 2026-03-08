class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.references :item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
