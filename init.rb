require 'redmine'
require_relative 'lib/redmine_time_entry_audit'
require_relative 'lib/redmine_time_entry_audit/hooks'

Redmine::Plugin.register :redmine_time_entry_audit do
  name        'Time Entry Audit'
  author      'Dobril Dobrilov'
  url 'https://github.com/dobrildobrilov/redmine_time_entry_audit'
  description 'Audit trail for TimeEntry with filters and exports'
  version     '1.0.1'

  permission :view_time_entry_audits, { time_entry_audits: [:index, :counts] }, read: true

  menu :project_menu, :time_entry_audits, { controller: 'time_entry_audits', action: 'index' },
       caption: 'Time Audit', after: :activity, param: :project_id,
       if: Proc.new { |p| TimeEntryAuditAccess.allowed?(User.current) }

  settings default: { 'allowed_admin_ids' => [] },
           partial: 'settings/time_entry_audit_settings'
end

if defined?(Mime::Type)
  Mime::Type.register('text/csv', :csv) unless Mime::Type.lookup_by_extension(:csv)
  Mime::Type.register('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx) unless Mime::Type.lookup_by_extension(:xlsx)
end

module TimeEntryAuditAccess
  module_function
  def allowed?(user)
    return false unless user&.logged?

    fresh_install = !::Setting.where(name: 'plugin_redmine_time_entry_audit').exists?
    return user.admin? if fresh_install

    s = Setting.plugin_redmine_time_entry_audit || {}
    ids = Array(s['allowed_admin_ids']).map(&:to_i)
    ids.include?(user.id)
  end
end


class TimeEntryAuditHooks < Redmine::Hook::ViewListener
  render_on :view_timelog_edit_form_bottom, partial: 'time_entry_audits/link'
end

Rails.configuration.to_prepare do
  require_dependency File.expand_path('app/patches/time_entry_patch', __dir__)
end
