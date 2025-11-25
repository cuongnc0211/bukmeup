class AddCurrencyToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :currency, :string, limit: 3, default: "VND", null: false
  end
end
