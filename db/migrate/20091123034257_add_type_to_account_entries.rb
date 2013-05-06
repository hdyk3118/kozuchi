# -*- encoding : utf-8 -*-

class AddTypeToAccountEntries < ActiveRecord::Migration
  def self.up
    add_column :account_entries, :type, :string
    execute "update account_entries set type = deals.type from deals where account_entries.deal_id = deals.id;"
  end

  def self.down
    remove_column :account_entries, :type
  end
end
