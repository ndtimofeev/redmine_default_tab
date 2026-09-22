# Redmine Default Tab

A small Redmine plugin that lets each project redirect from the **Overview**
tab to a different tab of your choice — Issues, Wiki, Activity, or whatever
the project actually uses as its front page.

## Why

Redmine always opens a project on Overview. For teams that live in Issues,
Wiki or Activity, that's an extra click on every visit. This plugin adds a
per-project setting for the tab that should open instead, and redirects
plain project visits there.

## How it works

- A `Project` custom field (**Default tab** by default) stores the name of
  the target `project_menu` item (e.g. `issues`, `wiki`, `activity`).
- The field's list of options is built dynamically from
  `Redmine::MenuManager.items(:project_menu)`, filtered to whatever is
  actually enabled and permitted in that project — including tabs
  contributed by other plugins.
- On every plain visit to a project (`GET /projects/:id`), the plugin
  checks that field. If it holds a still-valid tab, it redirects there
  using Redmine's own `redirect_to_project_menu_item`. Otherwise (field
  empty, module disabled, no permission, item no longer exists) nothing
  happens and Overview renders as usual.
- The Overview entry in the project menu is re-pointed to `?jump=overview`
  so it stays one click away and isn't shadowed by the redirect.
- API requests (`.json` / `.xml`) are never redirected.

### Why the controller patch is wired from two hooks

`init.rb` applies the `ProjectsController` patch and the Overview menu
change from both `Rails.application.config.to_prepare` and
`Rails.application.config.after_initialize`. `to_prepare` is the
textbook-correct hook — it also re-applies the patch after a
development-mode class reload — but on at least one real install it never
fired at all, for reasons that weren't tracked down (see TODO.md).
`after_initialize` is a plainer hook that always runs exactly once per
boot, and it did fire there, so it's kept as a working fallback.

Both hooks call the same idempotent setup function, so it's safe if both
actually end up firing: the `prepend` is guarded by an `ancestors` check
(a second call is a no-op), and the menu item is always deleted before
being re-pushed, so re-running it just recreates the same entry rather than
producing a duplicate.

## Requirements

Redmine 5.0 or later. The plugin relies on the `Redmine::FieldFormat` and
`Redmine::MenuManager` APIs, which have been stable across the 5.x/6.x
line.

## Installation

```sh
cd redmine/plugins
git clone https://github.com/ndtimofeev/redmine_default_tab.git
cd ../..
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Restart Redmine afterwards.

## Usage

1. Open a project's **Settings → Information** tab.
2. Fill in the **Default tab** field with the tab that should open instead
   of Overview. Only tabs currently enabled and visible in this project are
   offered.
3. Leave it empty to keep the default Overview behavior.

Renaming the field itself (for example to Russian, or to something more
specific to your team) is safe: the plugin identifies its field by its
internal format, not by its name, so Administration → Custom fields →
rename works with no extra configuration.

## Uninstalling

Removing the plugin's files does not touch the stored per-project values or
the custom field itself — Redmine falls back to rendering it as a plain
text field. Re-adding the plugin picks the same values right back up. A
plain migration rollback (`rake redmine:plugins:migrate NAME=redmine_default_tab
VERSION=0`) deliberately does the same — it leaves the custom field alone —
so that an accidental or routine rollback can never silently erase every
project's configured tab.

### Removing it for good (and reinstalling from scratch)

To actually drop the custom field and every project's stored value along
with it, opt in explicitly with `REDMINE_DEFAULT_TAB_PURGE=1`:

```sh
cd redmine
REDMINE_DEFAULT_TAB_PURGE=1 bundle exec rake redmine:plugins:migrate \
  NAME=redmine_default_tab VERSION=0 RAILS_ENV=production
rm -rf plugins/redmine_default_tab
```

Restart Redmine. This also clears Redmine's record of the plugin's migration
state, so a later fresh install (re-clone into `plugins/redmine_default_tab`
and run `rake redmine:plugins:migrate RAILS_ENV=production` again) creates
the custom field from scratch instead of assuming it's already there.

## License

[MIT](LICENSE)
