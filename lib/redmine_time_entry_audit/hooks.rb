module RedmineTimeEntryAudit
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      ctrl = context[:controller]
      req  = context[:request]
      return ''.html_safe unless ctrl

      on_audits = (ctrl.controller_name == 'time_entry_audits')
      on_settings = (ctrl.controller_name == 'settings' &&
                     ctrl.action_name == 'plugin' &&
                     req&.params[:id] == 'redmine_time_entry_audit')

      css_js = ''
      if on_audits || on_settings
        css_js = stylesheet_link_tag('time_entry_audit', plugin: 'redmine_time_entry_audit') +
                 javascript_include_tag('time_entry_audit', plugin: 'redmine_time_entry_audit')
      end
      on_plugins_index = (ctrl.controller_name == 'admin' && ctrl.action_name == 'plugins')
      if on_plugins_index
        fresh_install = !::Setting.where(name: 'plugin_redmine_time_entry_audit').exists?
        if !fresh_install && !TimeEntryAuditAccess.allowed?(User.current)
          css_hide = 'a[href*="/settings/plugin/redmine_time_entry_audit"]{display:none !important;}'
          css_js << content_tag(:style, css_hide.html_safe)
        end
      end

      css_js.html_safe
    end
  end
end

