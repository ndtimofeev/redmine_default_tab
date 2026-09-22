# frozen_string_literal: true

require_relative 'lib/redmine_default_tab'
require_relative 'lib/redmine_default_tab/tab_resolver'
require_relative 'lib/redmine_default_tab/field_formats/default_tab_format'
require_relative 'lib/redmine_default_tab/patches/projects_controller_patch'

Redmine::Plugin.register :redmine_default_tab do
  name 'Default Tab'
  author 'ndtimofeev'
  description 'Lets each project redirect from Overview to a configured default tab.'
  version '0.1.0'
  url 'https://github.com/ndtimofeev/redmine_default_tab'

  requires_redmine version_or_higher: '5.0.0'
end

# Wires the controller patch and the Overview menu item. Idempotent (guarded
# by the ancestors check), so it's safe to call more than once.
redmine_default_tab_setup = lambda do
  unless ProjectsController.include?(RedmineDefaultTab::Patches::ProjectsControllerPatch)
    ProjectsController.prepend RedmineDefaultTab::Patches::ProjectsControllerPatch
  end

  # Re-point the Overview entry so it stays reachable: see the comment in
  # ProjectsControllerPatch#show for why the ?jump=overview marker matters.
  # menu.delete on an already-removed item is a no-op, so calling this twice
  # (once per hook below) is harmless.
  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete(:overview)
    menu.push :overview,
              { controller: 'projects', action: 'show', jump: 'overview' },
              caption: :label_overview, first: true
  end
end

# to_prepare is the textbook hook for this (it also re-applies the patch
# after a development-mode class reload), but it failed to fire at all on
# at least one real install; after_initialize is a plainer, always-once-
# per-boot hook that reliably did. Wiring both — the setup above is
# idempotent — covers both cases without needing to track down why.
Rails.application.config.to_prepare { redmine_default_tab_setup.call }
Rails.application.config.after_initialize { redmine_default_tab_setup.call }
