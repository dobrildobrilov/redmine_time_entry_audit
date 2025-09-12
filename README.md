# Redmine Time Entry Audit

Audit trail for **Spent time** entries in Redmine (create / update / destroy) with filters, diff-style visualization, and export to **CSV / JSON / XLSX**. Designed for Redmine 6.x.

---

## Features

- Full change log for `TimeEntry`:
  - `hours` (**DECIMAL(10,2)**), `comments`, `spent_on`
  - `activity_id`, `issue_id`, `user_id` (owner), `author_id`
- Records both `old_*` and `new_*` values.
- Snapshot fields to preserve readable labels even if records are deleted later:
  - `project_name`, `actor_login`, `old/new_user_login`,
    `old/new_author_login`, `old/new_activity_name`, `issue_subject`
- Project menu page **Time Audit** (visible only to allowed admins)
- Filters: period (by audit’s `created_at`), time entry ID, project (ID or identifier), **User (owner)**, **Actor**, **Action**, **Activity**
- Diff-style table with bold “before → after”; **Show only changes** option
- Exports: **CSV / JSON / XLSX** (via `caxlsx`)
- In Spent time edit form: **View time entry history** (+ quick CSV export)
- History indicator API:
  - `GET /time_entry_audits/counts?ids[]=123&ids[]=456`
    → `{ "123": 2, "456": 0 }`
- Access control:
  - Settings field `allowed_admin_ids` (multi-select)
  - **Configure** is hidden for non-allowed users and guarded with **404**

---

## Requirements

- Redmine **6.x** (tested with **6.0.6**)
- Ruby **3.1+**
- MySQL/MariaDB or PostgreSQL
- Gem: [`caxlsx`](https://github.com/caxlsx/caxlsx) (included via the plugin’s `Gemfile`)

---

## Installation

```bash
cd /path/to/redmine

# If you use git
git clone https://github.com/dobrildobrilov/redmine_time_entry_audit.git plugins/redmine_time_entry_audit

# Or unzip a release
# unzip redmine_time_entry_audit-*.zip -d plugins/

bundle install
RAILS_ENV=production bundle exec rake redmine:plugins:migrate

# Restart the application server (Passenger/Puma/Unicorn)

