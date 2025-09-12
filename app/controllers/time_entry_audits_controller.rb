class TimeEntryAuditsController < ApplicationController
  before_action :find_optional_project
  before_action :require_login
  before_action :ensure_allowed!

  def index
    @time_entry_id = params[:time_entry_id].presence
    @from  = parse_date(params[:from])
    @to    = parse_date(params[:to])
    @user_id   = params[:user_id].presence
    @actor_id  = params[:actor_id].presence
    @action    = params[:what].presence
    @activity_id = params[:activity_id].presence
    @proj_param = params[:project_id].presence || params[:id].presence

    scope = TimeEntryAudit.order(created_at: :desc)
    scope = scope.where(time_entry_id: @time_entry_id) if @time_entry_id

    if @proj_param
      pid = if @proj_param.to_s =~ /^\d+$/; @proj_param.to_i; else; Project.find_by(identifier: @proj_param)&.id; end
      scope = scope.where(project_id: pid) if pid
    end

    scope = scope.where('created_at >= ?', @from.beginning_of_day) if @from
    scope = scope.where('created_at <= ?', @to.end_of_day) if @to
    scope = scope.where('old_user_id = :uid OR new_user_id = :uid', uid: @user_id.to_i) if @user_id
    scope = scope.where(actor_id: @actor_id.to_i) if @actor_id
    scope = scope.where(action: @action) if @action
    scope = scope.where('old_activity_id = :aid OR new_activity_id = :aid', aid: @activity_id.to_i) if @activity_id

    @audits = scope.limit(5000)

    @projects_list = Project.visible.order(:name).limit(1000)
    @users_list    = User.active.order(:login).limit(1000)
    @activities    = TimeEntryActivity.order(:position)

    if params[:download].to_s == 'json'
      send_data audits_json(@audits).to_json, filename: build_filename('json'), type: 'application/json' and return
    end

    respond_to do |format|
      format.html
      format.csv  { send_data to_csv(@audits), filename: build_filename('csv') }
      format.json { render json: audits_json(@audits) }
      format.xlsx { send_data to_xlsx(@audits), filename: build_filename('xlsx'),
                              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
      format.any  { render :index }  # 406 safeguard
    end
  end

  def counts
    ids = Array.wrap(params[:ids]).map(&:to_i).uniq
    data = TimeEntryAudit.where(time_entry_id: ids).group(:time_entry_id).count
    render json: data
  end

  private

  def ensure_allowed!
    render_404 unless TimeEntryAuditAccess.allowed?(User.current)
  end

  def build_filename(ext)
    base = 'time_entry_audit'
    base += "-#{@time_entry_id}" if @time_entry_id
    base += "-from#{@from}" if @from
    base += "-to#{@to}" if @to
    base + ".#{ext}"
  end

  def parse_date(v)
    return nil if v.blank?
    v.is_a?(Date) ? v : (Date.parse(v) rescue nil)
  end

  def issue_label_from(a)
    iid = a.issue_id || a.new_issue_id || a.old_issue_id
    return nil unless iid
    subj = a.issue_subject.presence
    return "##{iid} – #{subj}" if subj
    is = Issue.find_by(id: iid)
    is ? "##{iid} – #{is.subject}" : "##{iid}"
  end

  def activity_names(a)
    old_name = a.old_activity_name.presence
    new_name = a.new_activity_name.presence
    if old_name || new_name
      [old_name, new_name]
    else
      old_act = TimeEntryActivity.find_by(id: a.old_activity_id)
      new_act = TimeEntryActivity.find_by(id: a.new_activity_id)
      [old_act&.name, new_act&.name]
    end
  end

  def actor_login(a)
    a.actor_login.presence || User.find_by(id: a.actor_id)&.login || a.actor_id
  end

  def project_name(a)
    a.project_name.presence || Project.find_by(id: a.project_id)&.name
  end

  def audits_json(audits)
    audits.map do |a|
      old_act_name, new_act_name = activity_names(a)
      {
        id: a.id,
        when: a.created_at,
        action: a.action,
        actor: actor_login(a),
        project: project_name(a),
        entry: a.time_entry_id,
        issue: issue_label_from(a),
        activity: [old_act_name || a.old_activity_id, new_act_name || a.new_activity_id].compact.join(' → '),
        hours: [a.old_hours, a.new_hours].compact.join(' → '),
        comment: [a.old_comments, a.new_comments].compact.join(' → '),
        date: [a.old_spent_on, a.new_spent_on].compact.join(' → '),
        user: [(a.old_user_login.presence || a.old_user&.login || a.old_user_id),
               (a.new_user_login.presence || a.new_user&.login || a.new_user_id)].compact.join(' → '),
        author: [(a.old_author_login.presence || a.old_author&.login || a.old_author_id),
                 (a.new_author_login.presence || a.new_author&.login || a.new_author_id)].compact.join(' → ')
      }
    end
  end

  def to_csv(audits)
    require 'csv'
    CSV.generate(force_quotes: true) do |csv|
      csv << %w[When Actor Action Entry Project Hours Comment Date Activity Issue User Author]
      audits.each do |a|
        old_act_name, new_act_name = activity_names(a)
        csv << [
          a.created_at,
          actor_login(a),
          a.action,
          a.time_entry_id,
          project_name(a),
          [a.old_hours, a.new_hours].compact.join(' → '),
          [a.old_comments, a.new_comments].compact.join(' → '),
          [a.old_spent_on, a.new_spent_on].compact.join(' → '),
          [(old_act_name || a.old_activity_id), (new_act_name || a.new_activity_id)].compact.join(' → '),
          issue_label_from(a),
          [(a.old_user_login.presence || a.old_user&.login || a.old_user_id),
           (a.new_user_login.presence || a.new_user&.login || a.new_user_id)].compact.join(' → '),
          [(a.old_author_login.presence || a.old_author&.login || a.old_author_id),
           (a.new_author_login.presence || a.new_author&.login || a.new_author_id)].compact.join(' → ')
        ]
      end
    end
  end

  def to_xlsx(audits)
    require 'caxlsx'
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(name: 'Time Entry Audit') do |sheet|
      header = %w[When Actor Action Entry Project Hours Comment Date Activity Issue User Author]
      sheet.add_row(header)
      audits.each do |a|
        old_act_name, new_act_name = activity_names(a)
        sheet.add_row([
          a.created_at,
          actor_login(a),
          a.action,
          a.time_entry_id,
          project_name(a),
          [a.old_hours, a.new_hours].compact.join(' → '),
          [a.old_comments, a.new_comments].compact.join(' → '),
          [a.old_spent_on, a.new_spent_on].compact.join(' → '),
          [(old_act_name || a.old_activity_id), (new_act_name || a.new_activity_id)].compact.join(' → '),
          issue_label_from(a),
          [(a.old_user_login.presence || a.old_user&.login || a.old_user_id),
           (a.new_user_login.presence || a.new_user&.login || a.new_user_id)].compact.join(' → '),
          [(a.old_author_login.presence || a.old_author&.login || a.old_author_id),
           (a.new_author_login.presence || a.new_author&.login || a.new_author_id)].compact.join(' → ')
        ])
      end
    end
    p.to_stream.read
  end

  def find_optional_project
    pid = params[:project_id].presence || params[:id].presence
    if pid.present?
      if pid.to_s =~ /^\d+$/
        @project = Project.find_by(id: pid.to_i)
      else
        @project = Project.find_by(identifier: pid)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
