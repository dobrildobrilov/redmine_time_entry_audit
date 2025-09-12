class CreateTimeEntryAudits < ActiveRecord::Migration[7.0]
  def change
    create_table :time_entry_audits do |t|
      t.integer :time_entry_id, null: false
      t.integer :project_id
      t.integer :issue_id
      t.integer :activity_id
      t.integer :actor_id,     null: false
      t.string  :action,       null: false
      t.decimal :old_hours, precision: 10, scale: 2
      t.decimal :new_hours, precision: 10, scale: 2
      t.text    :old_comments
      t.text    :new_comments
      t.date    :old_spent_on
      t.date    :new_spent_on
      t.integer :old_activity_id
      t.integer :new_activity_id
      t.integer :old_issue_id
      t.integer :new_issue_id
      t.integer :old_user_id
      t.integer :new_user_id
      t.integer :old_author_id
      t.integer :new_author_id
      t.datetime :created_at, null: false, precision: 0
      t.datetime :updated_at, null: false, precision: 0
    end
    add_index :time_entry_audits, :time_entry_id
    add_index :time_entry_audits, :actor_id
    add_index :time_entry_audits, :project_id
  end
end
