# frozen_string_literal: true

module RedmineDefaultTab
  module FieldFormats
    # A list-formatted project custom field whose options are computed on
    # every render from the live project_menu, instead of a static
    # possible_values array — so tabs added by other plugins, or removed
    # modules, are reflected immediately.
    class DefaultTabFormat < Redmine::FieldFormat::ListFormat
      add RedmineDefaultTab::FIELD_FORMAT

      # Only meaningful on projects; don't offer it when creating a custom
      # field for issues, users, etc.
      self.customized_class_names = %w[Project]

      def possible_custom_value_options(custom_value)
        options_for(custom_value.customized)
      end

      def possible_values_options(_custom_field, object = nil)
        options_for(object)
      end

      # The parent implementation requires a static possible_values array
      # on the custom field, which we don't use — options are always
      # computed dynamically, so there's nothing to validate here.
      def validate_custom_field(_custom_field)
        []
      end

      def validate_custom_value(custom_value)
        value = custom_value.value
        return [] if value.blank?

        allowed = options_for(custom_value.customized).map(&:last)
        return [] if allowed.include?(value)

        [::I18n.t('activerecord.errors.messages.inclusion')]
      end

      private

      def options_for(project)
        return [] unless project.is_a?(Project)

        TabResolver.available_items(project).map { |item| [item.caption(project).to_s, item.name.to_s] }
      end
    end
  end
end
