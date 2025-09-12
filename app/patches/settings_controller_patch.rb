require_dependency 'settings_controller'

module ::SettingsControllerPatch
  extend ActiveSupport::Concern

  included do
    before_action :tea_restrict_plugin_config, only: [:plugin]
  end

  private

  def tea_restrict_plugin_config
    return unless params[:id] == 'redmine_time_entry_audit'

    ids = Array(Setting.plugin_redmine_time_entry_audit['allowed_admin_ids']).map(&:to_i)
    allowed = ids.include?(User.current.id)
    render_403 unless allowed
  end
end

SettingsController.send(:include, ::SettingsControllerPatch) \
  unless SettingsController.included_modules.include?(::SettingsControllerPatch)

