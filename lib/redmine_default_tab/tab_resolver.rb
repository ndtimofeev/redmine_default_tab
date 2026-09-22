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
    def available_items(project)
      return [] unless project

      items = Redmine::MenuManager.items(:project_menu).root.children.select do |item|
        !EXCLUDED_ITEMS.include?(item.name) && item.allowed?(User.current, project)
      end

      Rails.logger.info(
        "#{LOG_TAG} available_items: project=#{project.identifier.inspect} (id=#{project.id}) " \
        "user=#{User.current.login.inspect} (id=#{User.current.id}) -> #{items.map(&:name).inspect}"
      )
      items
    end

    # The project's configured default tab, or nil if it's unset, or no
    # longer valid (module disabled, permission missing, item removed by
    # an uninstalled plugin).
    def resolve(project)
      unless project
        Rails.logger.info("#{LOG_TAG} resolve: no project given, skipping")
        return nil
      end

      custom_field = default_tab_custom_field
      unless custom_field
        Rails.logger.info("#{LOG_TAG} resolve: no custom field found for project=#{project.identifier.inspect}, skipping")
        return nil
      end

      value = project.custom_field_value(custom_field)
      Rails.logger.info(
        "#{LOG_TAG} resolve: project=#{project.identifier.inspect} (id=#{project.id}) " \
        "custom_field_id=#{custom_field.id} stored_value=#{value.inspect}"
      )

      if value.blank?
        Rails.logger.info("#{LOG_TAG} resolve: stored value is blank, nothing to redirect to")
        return nil
      end

      valid_names = available_items(project).map { |item| item.name.to_s }
      if valid_names.include?(value)
        Rails.logger.info("#{LOG_TAG} resolve: #{value.inspect} is a valid tab -> redirecting")
        value
      else
        Rails.logger.info(
          "#{LOG_TAG} resolve: #{value.inspect} is NOT among valid tabs #{valid_names.inspect} " \
          '-> falling back to Overview'
        )
        nil
      end
    end

    # Looked up by field_format, not by name: the name is free for an
    # admin to change via the regular custom field edit form.
    def default_tab_custom_field
      field = ProjectCustomField.find_by(field_format: RedmineDefaultTab::FIELD_FORMAT)
      found = field ? "id=#{field.id} name=#{field.name.inspect}" : 'NOT FOUND'
      Rails.logger.info(
        "#{LOG_TAG} default_tab_custom_field: looked up field_format=#{RedmineDefaultTab::FIELD_FORMAT.inspect} -> #{found}"
      )
      field
    end
  end
end
