class CreateProakas < ActiveRecord::Migration[6.1]
  def change
    create_table :proakas do |t|
      t.string :name, limit: 20, null: false

      t.timestamps
    end
  end
end
