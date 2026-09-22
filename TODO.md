# TODO

- [ ] Automated tests against the Redmine plugin test harness (fixtures for
      `Project`, `ProjectCustomField`, and `TabResolver`/`DefaultTabFormat`
      specs).
- [ ] Optional plugin Settings page to restrict which menu items may be
      offered as a default tab (right now every enabled/allowed item is
      offered).
- [ ] Confirm the desired behavior when another plugin removes or renames a
      `project_menu` item that is currently selected as someone's default
      tab — it currently just falls back to Overview on the next visit.
- [ ] CI workflow (lint + tests) for pull requests.
- [ ] Add a screenshot of the project settings field to the README.
- [ ] Decide whether `TabResolver::EXCLUDED_ITEMS` (`overview`, `settings`)
      should be configurable instead of hardcoded.
- [ ] `Rails.application.config.to_prepare` never fired at all on one real
      install (confirmed via diagnostic logging), for reasons not tracked
      down; `init.rb` currently also wires the patch from `after_initialize`
      as a working fallback. Worth understanding why `to_prepare` was silent
      there — if it truly never fires on some installs, this plugin's patch
      would not survive a development-mode class reload on them.
- [ ] `TabResolver.available_items` only walks the top-level
      `project_menu` items (`.root.children`), but core Redmine's
      `redirect_to_project_menu_item` resolves a name against the *entire*
      menu tree recursively (it also matches nested items, e.g. children
      registered under `:new_object`). If some plugin ever registers a
      nested item whose name collides with a top-level one we validated,
      the two lookups could disagree about which item a stored value
      refers to. Unlikely in practice (menu item names are informally
      expected to be unique), but worth either matching the same traversal
      depth or asserting uniqueness somewhere.
