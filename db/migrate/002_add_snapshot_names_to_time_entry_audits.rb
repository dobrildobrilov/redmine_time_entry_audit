class AddSnapshotNamesToTimeEntryAudits < ActiveRecord::Migration[7.0]
  def change
    change_table :time_entry_audits do |t|
      t.string  :project_name
      t.string  :actor_login
      t.string  :old_user_login
      t.string  :new_user_login
      t.string  :old_author_login
      t.string  :new_author_login
      t.string  :old_activity_name
      t.string  :new_activity_name
      t.string  :issue_subject
    end
  end
end
