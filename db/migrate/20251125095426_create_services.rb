class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, limit: 100, null: false
      t.text :description
      t.integer :duration_minutes, null: false
      t.integer :price_cents, null: false
      t.string :currency, limit: 3, default: "VND", null: false
      t.boolean :active, default: true
      t.integer :position, default: 0

      t.timestamps
    end

    # Add composite indexes for performance
    add_index :services, [ :business_id, :position ]
    add_index :services, [ :business_id, :active ]
  end
end
