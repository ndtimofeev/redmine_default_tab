# frozen_string_literal: true

module RedmineDefaultTab
  module Patches
    # Redirects a plain visit to a project (GET /projects/:id) to its
    # configured default tab instead of rendering Overview.
    module ProjectsControllerPatch
      def show
        # The Overview menu item points here with ?jump=overview so it
        # stays reachable. Strip the marker and render normally — without
        # this, Redmine's own jump handling in `super` would immediately
        # redirect back to plain /projects/:id (dropping the param) and we
        # would bounce it straight back to the default tab.
        if params[:jump] == 'overview'
          params.delete(:jump)
          return super
        end

        # Any other jump target (header "Jump to a project" box, links
        # from other plugins) is left alone — only take over a plain visit.
        if params[:jump].blank? && request.format.html?
          tab = RedmineDefaultTab::TabResolver.resolve(@project)
          return if tab && redirect_to_project_menu_item(@project, tab)
        end

        super
      end
    end
  end
end
