class CreateXapiMiddlewareResults < ActiveRecord::Migration[7.1]
  def up
    create_table :xapi_middleware_results do |t|
      t.decimal :score_scaled, precision: 3, scale: 2
      t.integer :score_raw
      t.integer :score_min
      t.integer :score_max
      t.boolean :success, default: false
      t.boolean :completion, default: false
      t.text :response
      t.string :duration
      t.bigint :statement_id, null: false
    end

    add_index :xapi_middleware_results, :statement_id
  end

  def down
    drop_table :xapi_middleware_results
  end
end
