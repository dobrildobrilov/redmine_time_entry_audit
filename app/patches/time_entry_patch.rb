require_dependency 'time_entry'
module TimeEntryPatch
  extend ActiveSupport::Concern
  included do
    after_create  :audit_after_create
    before_update :capture_before_update_snapshot
    after_update  :audit_after_update
    after_destroy :audit_after_destroy
    attr_accessor :audit_old
  end
  private
  def capture_before_update_snapshot
    self.audit_old = {
      hours:       self.hours_in_database,
      comments:    self.comments_in_database,
      spent_on:    self.spent_on_in_database,
      activity_id: self.activity_id_in_database,
      issue_id:    self.issue_id_in_database,
      user_id:     self.user_id_in_database,
      author_id:   self.author_id_in_database
    }; true
  end
  def audit_after_create
    prj = Project.find_by(id: project_id)
    iss = Issue.find_by(id: issue_id)
    act = TimeEntryActivity.find_by(id: activity_id)
    curr = User.current
    owner = User.find_by(id: user_id)
    auth  = User.find_by(id: author_id)
    TimeEntryAudit.create!({
      time_entry_id: id,
      project_id: project_id, project_name: prj&.name,
      issue_id: issue_id, issue_subject: iss&.subject,
      activity_id: activity_id, old_activity_name: nil, new_activity_name: act&.name,
      actor_id: curr.id, actor_login: curr.login, action: 'create',
      old_hours: nil, new_hours: self.hours,
      old_comments: nil, new_comments: self.comments,
      old_spent_on: nil, new_spent_on: self.spent_on,
      old_activity_id: nil, new_activity_id: self.activity_id,
      old_issue_id: nil, new_issue_id: self.issue_id,
      old_user_id: nil, new_user_id: self.user_id, old_user_login: nil, new_user_login: owner&.login,
      old_author_id: nil, new_author_id: self.author_id, old_author_login: nil, new_author_login: auth&.login
    })
  end
  def audit_after_update
    prj = Project.find_by(id: project_id)
    iss = Issue.find_by(id: issue_id)
    old = audit_old || {}
    act_old = TimeEntryActivity.find_by(id: old[:activity_id])
    act_new = TimeEntryActivity.find_by(id: activity_id)
    curr = User.current
    owner_old = User.find_by(id: old[:user_id]); owner_new = User.find_by(id: user_id)
    auth_old  = User.find_by(id: old[:author_id]); auth_new  = User.find_by(id: author_id)
    changed = %i[hours comments spent_on activity_id issue_id user_id author_id].any? { |a| saved_change_to_attribute?(a) }
    return unless changed
    TimeEntryAudit.create!({
      time_entry_id: id,
      project_id: project_id, project_name: prj&.name,
      issue_id: issue_id, issue_subject: iss&.subject,
      activity_id: activity_id, old_activity_name: act_old&.name, new_activity_name: act_new&.name,
      actor_id: curr.id, actor_login: curr.login, action: 'update',
      old_hours: old[:hours], new_hours: self.hours,
      old_comments: old[:comments], new_comments: self.comments,
      old_spent_on: old[:spent_on], new_spent_on: self.spent_on,
      old_activity_id: old[:activity_id], new_activity_id: self.activity_id,
      old_issue_id: old[:issue_id], new_issue_id: self.issue_id,
      old_user_id: old[:user_id], new_user_id: self.user_id, old_user_login: owner_old&.login, new_user_login: owner_new&.login,
      old_author_id: old[:author_id], new_author_id: self.author_id, old_author_login: auth_old&.login, new_author_login: auth_new&.login
    })
  end
  def audit_after_destroy
    prj = Project.find_by(id: project_id)
    iss = Issue.find_by(id: issue_id)
    act = TimeEntryActivity.find_by(id: activity_id)
    curr = User.current
    owner = User.find_by(id: user_id)
    auth  = User.find_by(id: author_id)
    TimeEntryAudit.create!({
      time_entry_id: id,
      project_id: project_id, project_name: prj&.name,
      issue_id: issue_id, issue_subject: iss&.subject,
      activity_id: activity_id, old_activity_name: act&.name, new_activity_name: nil,
      actor_id: curr.id, actor_login: curr.login, action: 'destroy',
      old_hours: self.hours, new_hours: nil,
      old_comments: self.comments, new_comments: nil,
      old_spent_on: self.spent_on, new_spent_on: nil,
      old_activity_id: self.activity_id, new_activity_id: nil,
      old_issue_id: self.issue_id, new_issue_id: nil,
      old_user_id: self.user_id, new_user_id: nil, old_user_login: owner&.login, new_user_login: nil,
      old_author_id: self.author_id, new_author_id: nil, old_author_login: auth&.login, new_author_login: nil
    })
  end
end
TimeEntry.send(:include, TimeEntryPatch) unless TimeEntry.included_modules.include?(TimeEntryPatch)
