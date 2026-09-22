# frozen_string_literal: true

module RedmineDefaultTab
  # Resolves which project_menu tab (if any) a project should open on
  # instead of Overview, and lists the tabs that are valid choices for it.
  module TabResolver
    # Doesn't make sense as a redirect target: Overview is what we are
    # replacing, and Settings is normally only visible to project admins.
    EXCLUDED_ITEMS = %i[overview settings].freeze

    LOG_TAG = '[RedmineDefaultTab]'

    module_function

    # project_menu items actually available to the current user in this
    # project right now: MenuItem#allowed? already accounts for the
    # permission, the project module being enabled, and the item's :if
    # condition — the same check Redmine itself uses to render the menu.
    #
    # Items with a blank url (e.g. the "+" new-object button, which is a
    # pure JS dropdown trigger with url: nil and no page of its own) are
    # excluded on principle, not by name: allowed? treats such a "virtual"
    # node as valid whenever any of its children are, which is exactly why
    # it otherwise sneaks in here despite not being a real destination.
    def available_items(project)
      return [] unless project

      items = Redmine::MenuManager.items(:project_menu).root.children.select do |item|
        item.url.present? && !EXCLUDED_ITEMS.include?(item.name) && item.allowed?(User.current, project)
      end

      Rails.logger.debug(
        "#{LOG_TAG} available_items: project=#{project.identifier.inspect} (id=#{project.id}) " \
        "user=#{User.current.login.inspect} (id=#{User.current.id}) -> #{items.map(&:name).inspect}"
      )
      items
    end

    # The project's configured default tab, or nil if it's unset, or no
    # longer valid (module disabled, permission missing, item removed by
    # an uninstalled plugin).
    def resolve(project)
      return nil unless project

      custom_field = default_tab_custom_field
      return nil unless custom_field

      value = project.custom_field_value(custom_field)
      return nil if value.blank?

      valid_names = available_items(project).map { |item| item.name.to_s }
      unless valid_names.include?(value)
        Rails.logger.debug(
          "#{LOG_TAG} resolve: #{value.inspect} is not among valid tabs #{valid_names.inspect} for " \
          "project=#{project.identifier.inspect}, falling back to Overview"
        )
        return nil
      end

      value
    end

    # Looked up by field_format, not by name: the name is free for an
    # admin to change via the regular custom field edit form.
    def default_tab_custom_field
      ProjectCustomField.find_by(field_format: RedmineDefaultTab::FIELD_FORMAT)
    end
  end
end
