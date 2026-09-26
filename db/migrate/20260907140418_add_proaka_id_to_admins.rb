class AddProakaIdToAdmins < ActiveRecord::Migration[6.1]
  def up
    add_column :admins, :プロアカ_id, :bigint

    default_proaka = Proaka.order(:id).first || Proaka.create!(name: 'プロアカ1')
    Admin.update_all(プロアカ_id: default_proaka.id)

    change_column_null :admins, :プロアカ_id, false
    add_index :admins, :プロアカ_id
    add_foreign_key :admins, :proakas, column: :プロアカ_id
  end

  def down
    remove_foreign_key :admins, :proakas, column: :プロアカ_id
    remove_index :admins, :プロアカ_id
    remove_column :admins, :プロアカ_id
  end
end
