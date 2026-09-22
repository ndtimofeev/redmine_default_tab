# frozen_string_literal: true

module RedmineDefaultTab
  # Internal field_format identifier registered with Redmine::FieldFormat.
  # Used to find "our" custom field regardless of how it has been renamed
  # by an admin — see TabResolver.default_tab_custom_field.
  FIELD_FORMAT = 'default_tab'.freeze

  # Seed value for the custom field's display name, used once by the
  # migration that creates it. Renaming it afterwards through
  # Administration > Custom fields is fully supported.
  DEFAULT_CUSTOM_FIELD_NAME = 'Default tab'.freeze
end
