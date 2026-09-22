# frozen_string_literal: true

class CreateDefaultTabCustomField < ActiveRecord::Migration[6.1]
  def up
    return if ProjectCustomField.exists?(field_format: RedmineDefaultTab::FIELD_FORMAT)

    ProjectCustomField.create!(
      name: RedmineDefaultTab::DEFAULT_CUSTOM_FIELD_NAME,
      field_format: RedmineDefaultTab::FIELD_FORMAT,
      is_required: false,
      editable: true,
      visible: true
    )
  end

  def down
    # A plain rollback intentionally does NOT destroy the field — that
    # would silently wipe out every project's configured tab. Destroying
    # it is only ever done on purpose, opted into explicitly via this env
    # var. See README "Uninstalling" for the full recipe.
    return unless ENV['REDMINE_DEFAULT_TAB_PURGE'] == '1'

    ProjectCustomField.find_by(field_format: RedmineDefaultTab::FIELD_FORMAT)&.destroy
  end
end
