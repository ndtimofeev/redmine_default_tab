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

Rails.application.config.to_prepare do
  unless ProjectsController.include?(RedmineDefaultTab::Patches::ProjectsControllerPatch)
    ProjectsController.prepend RedmineDefaultTab::Patches::ProjectsControllerPatch
  end

  # Re-point the Overview entry so it stays reachable: see the comment in
  # ProjectsControllerPatch#show for why the ?jump=overview marker matters.
  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete(:overview)
    menu.push :overview,
              { controller: 'projects', action: 'show', jump: 'overview' },
              caption: :label_overview, first: true
  end
end
