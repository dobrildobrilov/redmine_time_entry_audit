class TimeEntryAudit < ActiveRecord::Base
  self.table_name = 'time_entry_audits'
  belongs_to :time_entry, optional: true
  belongs_to :project, optional: true
  belongs_to :issue, optional: true
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: :activity_id, optional: true
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :old_user, class_name: 'User', foreign_key: :old_user_id, optional: true
  belongs_to :new_user, class_name: 'User', foreign_key: :new_user_id, optional: true
  belongs_to :old_author, class_name: 'User', foreign_key: :old_author_id, optional: true
  belongs_to :new_author, class_name: 'User', foreign_key: :new_author_id, optional: true
  validates :time_entry_id, :actor_id, :action, presence: true
end
