class AddTenantIdToPosts < ActiveRecord::Migration[6.1]
  def up
    add_column :posts, :tenant_id, :bigint

    execute <<~SQL.squish
      UPDATE posts
      LEFT JOIN users  ON users.id  = posts.user_id
      LEFT JOIN admins ON admins.id = posts.admin_id
      SET posts.tenant_id = COALESCE(users.tenant_id, admins.tenant_id)
    SQL

    change_column_null :posts, :tenant_id, false
    add_index :posts, :tenant_id
    add_foreign_key :posts, :tenants
  end

  def down
    remove_foreign_key :posts, :tenants
    remove_index :posts, :tenant_id
    remove_column :posts, :tenant_id
  end
end
