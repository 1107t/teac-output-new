class AddTenantIdToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :tenant_id, :bigint

    # テナントが1件も無い環境（新規DB等）でも NOT NULL 化できるよう、無ければ作成する
    default_tenant_id = (Tenant.order(:id).first || Tenant.create!(name: 'デフォルト')).id
    User.update_all(tenant_id: default_tenant_id)

    change_column_null :users, :tenant_id, false
    add_index :users, :tenant_id
    add_foreign_key :users, :tenants
  end

  def down
    remove_foreign_key :users, :tenants
    remove_index :users, :tenant_id
    remove_column :users, :tenant_id
  end
end
