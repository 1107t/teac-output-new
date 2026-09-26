class AddProakaIdToUsers < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :プロアカ_id, :bigint

    default_proaka = Proaka.order(:id).first || Proaka.create!(name: 'プロアカ1')
    User.update_all(プロアカ_id: default_proaka.id)

    change_column_null :users, :プロアカ_id, false
    add_index :users, :プロアカ_id
    add_foreign_key :users, :proakas, column: :プロアカ_id
  end

  def down
    remove_foreign_key :users, :proakas, column: :プロアカ_id
    remove_index :users, :プロアカ_id
    remove_column :users, :プロアカ_id
  end
end
