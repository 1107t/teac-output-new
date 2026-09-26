class AddTenantIdToAdmins < ActiveRecord::Migration[6.1]
  def up
    add_column :admins, :tenant_id, :bigint

    default_tenant_id = Tenant.order(:id).first&.id
    Admin.update_all(tenant_id: default_tenant_id) if default_tenant_id

    change_column_null :admins, :tenant_id, false
    add_index :admins, :tenant_id
    add_foreign_key :admins, :tenants
  end

  def down
    remove_foreign_key :admins, :tenants
    remove_index :admins, :tenant_id
    remove_column :admins, :tenant_id
  end
end
