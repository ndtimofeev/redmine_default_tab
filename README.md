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
text field. Re-adding the plugin picks the same values right back up. The
migration's `down` step intentionally leaves the custom field in place for
the same reason; drop it by hand from Administration → Custom fields if you
really want it gone for good.

## License

Not yet decided — see [TODO.md](TODO.md).
