class AddTenantIdToTweets < ActiveRecord::Migration[6.1]
  def up
    add_column :tweets, :tenant_id, :bigint

    execute <<~SQL.squish
      UPDATE tweets
      JOIN users ON users.id = tweets.user_id
      SET tweets.tenant_id = users.tenant_id
    SQL

    change_column_null :tweets, :tenant_id, false
    add_index :tweets, :tenant_id
    add_foreign_key :tweets, :tenants
  end

  def down
    remove_foreign_key :tweets, :tenants
    remove_index :tweets, :tenant_id
    remove_column :tweets, :tenant_id
  end
end
