class AddTenantIdToArticles < ActiveRecord::Migration[6.1]
  def up
    add_column :articles, :tenant_id, :bigint

    execute <<~SQL.squish
      UPDATE articles
      LEFT JOIN users  ON users.id  = articles.user_id
      LEFT JOIN admins ON admins.id = articles.admin_id
      SET articles.tenant_id = COALESCE(users.tenant_id, admins.tenant_id)
    SQL

    change_column_null :articles, :tenant_id, false
    add_index :articles, :tenant_id
    add_foreign_key :articles, :tenants
  end

  def down
    remove_foreign_key :articles, :tenants
    remove_index :articles, :tenant_id
    remove_column :articles, :tenant_id
  end
end
