# frozen_string_literal: true

# Bypasses Rails.logger entirely (level/output config, log rotation, etc.)
# so this line shows up even if nothing else does: check the actual process
# stderr (journalctl / docker logs / passenger error log), not production.log.
warn "[RedmineDefaultTab] init.rb is being loaded from #{__FILE__} (pid=#{Process.pid})"

%w[
  lib/redmine_default_tab
  lib/redmine_default_tab/tab_resolver
  lib/redmine_default_tab/field_formats/default_tab_format
  lib/redmine_default_tab/patches/projects_controller_patch
].each do |path|
  require_relative path
  warn "[RedmineDefaultTab] loaded #{path}"
rescue Exception => e # rubocop:disable Lint/RescueException -- diagnostic only, re-raised below
  warn "[RedmineDefaultTab] FAILED to load #{path}: #{e.class}: #{e.message}\n#{e.backtrace&.take(10)&.join("\n")}"
  raise
end

Redmine::Plugin.register :redmine_default_tab do
  name 'Default Tab'
  author 'ndtimofeev'
  description 'Lets each project redirect from Overview to a configured default tab.'
  version '0.1.0'
  url 'https://github.com/ndtimofeev/redmine_default_tab'

  requires_redmine version_or_higher: '5.0.0'
end

warn "[RedmineDefaultTab] init.rb reached end of top-level code (pid=#{Process.pid})"

# Wires the controller patch and the Overview menu item. Idempotent (guarded
# by the ancestors check), so it's safe to call from more than one hook.
redmine_default_tab_setup = lambda do |hook_name|
  log_tag = RedmineDefaultTab::TabResolver::LOG_TAG
  warn "[RedmineDefaultTab] #{hook_name} is running (pid=#{Process.pid})"
  Rails.logger.info("#{log_tag} #{hook_name}: running, ProjectsController ancestors before = #{ProjectsController.ancestors.take(5).inspect}")

  unless ProjectsController.include?(RedmineDefaultTab::Patches::ProjectsControllerPatch)
    ProjectsController.prepend RedmineDefaultTab::Patches::ProjectsControllerPatch
    Rails.logger.info("#{log_tag} #{hook_name}: prepended ProjectsControllerPatch")
  else
    Rails.logger.info("#{log_tag} #{hook_name}: ProjectsControllerPatch already present, skipped prepend")
  end

  Rails.logger.info("#{log_tag} #{hook_name}: ProjectsController ancestors after = #{ProjectsController.ancestors.take(5).inspect}")

  # Re-point the Overview entry so it stays reachable: see the comment in
  # ProjectsControllerPatch#show for why the ?jump=overview marker matters.
  # menu.delete on an already-removed item is a no-op, so calling this twice
  # (once per hook, if both fire) is harmless.
  Redmine::MenuManager.map :project_menu do |menu|
    menu.delete(:overview)
    menu.push :overview,
              { controller: 'projects', action: 'show', jump: 'overview' },
              caption: :label_overview, first: true
  end

  Rails.logger.info("#{log_tag} #{hook_name}: done")
rescue StandardError => e
  Rails.logger.error("#{RedmineDefaultTab::TabResolver::LOG_TAG} #{hook_name}: RAISED #{e.class}: #{e.message}\n#{e.backtrace&.take(10)&.join("\n")}")
  warn "[RedmineDefaultTab] #{hook_name} RAISED #{e.class}: #{e.message}"
  raise
end

# to_prepare is the "correct" hook (also re-applies the patch after a
# development-mode class reload), but it didn't fire at all in a previous
# diagnostic run on this install — keeping it registered while we find out
# why, and backing it up with after_initialize below, which is a plainer,
# always-once hook that every full Rails boot (server, console, rake) runs.
Rails.application.config.to_prepare do
  redmine_default_tab_setup.call('to_prepare')
end

Rails.application.config.after_initialize do
  redmine_default_tab_setup.call('after_initialize')
end
