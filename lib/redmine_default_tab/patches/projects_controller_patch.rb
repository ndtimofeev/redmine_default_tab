# frozen_string_literal: true

module RedmineDefaultTab
  module Patches
    # Redirects a plain visit to a project (GET /projects/:id) to its
    # configured default tab instead of rendering Overview.
    module ProjectsControllerPatch
      LOG_TAG = RedmineDefaultTab::TabResolver::LOG_TAG

      def show
        Rails.logger.info(
          "#{LOG_TAG} show: project=#{@project&.identifier.inspect} (id=#{@project&.id}) " \
          "jump=#{params[:jump].inspect} format=#{request.format} user=#{User.current.login.inspect}"
        )

        # The Overview menu item points here with ?jump=overview so it
        # stays reachable. Strip the marker and render normally — without
        # this, Redmine's own jump handling in `super` would immediately
        # redirect back to plain /projects/:id (dropping the param) and we
        # would bounce it straight back to the default tab.
        if params[:jump] == 'overview'
          Rails.logger.info("#{LOG_TAG} show: explicit ?jump=overview, clearing marker and rendering Overview")
          params.delete(:jump)
          return super
        end

        # Any other jump target (header "Jump to a project" box, links
        # from other plugins) is left alone — only take over a plain visit.
        if params[:jump].blank? && request.format.html?
          tab = RedmineDefaultTab::TabResolver.resolve(@project)

          if tab
            item = Redmine::MenuManager.items(:project_menu).detect { |i| i.name.to_s == tab.to_s }
            Rails.logger.info(
              "#{LOG_TAG} show: menu item for #{tab.inspect} = #{item.inspect}, " \
              "allowed?=#{item&.allowed?(User.current, @project).inspect}"
            )

            redirected = redirect_to_project_menu_item(@project, tab)
            Rails.logger.info("#{LOG_TAG} show: redirect_to_project_menu_item(#{tab.inspect}) -> #{redirected.inspect}")
            return if redirected
          end
        else
          Rails.logger.info("#{LOG_TAG} show: not attempting a redirect (jump param present or non-html format)")
        end

        Rails.logger.info("#{LOG_TAG} show: falling through to the original Overview rendering")
        super
      end
    end
  end
end
