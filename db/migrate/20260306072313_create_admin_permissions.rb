class CreateAdminPermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :resource, null: false
      t.boolean :can_read, null: false, default: false
      t.boolean :can_create, null: false, default: false
      t.boolean :can_update, null: false, default: false
      t.boolean :can_destroy, null: false, default: false

      t.timestamps
    end

    add_index :admin_permissions, [:user_id, :resource], unique: true
  end
end