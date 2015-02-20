require 'active_record'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
ActiveRecord::Schema.define do
  self.verbose = false

  # TODO: add a generator for migrations
  create_table :pricing_definitions, force: true do |t|
    t.date :starts_at, default: nil
    t.date :ends_at, default: nil
    t.integer :priceable_id, default: nil
    t.string :priceable_type, default: nil
    t.text :definition, default: {}
    t.integer :weight, default: 0
    t.timestamps null: false
  end

  create_table :test_priceables, force: true do |t|
    t.string :currency, default: nil
    t.integer :min_limit, default: 1
    t.integer :max_limit, default: nil
    t.timestamps null: false
  end

  create_table :modifier_without_required_attributes, force: true do |t|
    t.timestamps null: false
  end

  create_table :modifier_with_required_attributes, force: true do |t|
    t.boolean :additive, default: false
    t.boolean :fixed, default: false
    t.integer :amount, default: 1
    t.string :currency
    t.timestamps null: false
  end
end

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# Get rid off I18n deprecation messages
I18n.enforce_available_locales = false
