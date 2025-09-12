require_dependency 'settings_controller'

module ::SettingsControllerPatch
  extend ActiveSupport::Concern

  included do
    before_action :tea_restrict_plugin_config, only: [:plugin]
  end

  private
  def tea_restrict_plugin_config
  return unless params[:id] == 'redmine_time_entry_audit'

  fresh_install = !::Setting.where(name: 'plugin_redmine_time_entry_audit').exists?
  if fresh_install
    # докато няма запис – позволи на всеки admin да отваря Configure
    render_404 unless User.current.admin?
    return
  end

  s = Setting.plugin_redmine_time_entry_audit || {}
  ids = Array(s['allowed_admin_ids']).map(&:to_i)
  render_404 unless ids.include?(User.current.id)
  end

end

SettingsController.send(:include, ::SettingsControllerPatch) \
  unless SettingsController.included_modules.include?(::SettingsControllerPatch)

