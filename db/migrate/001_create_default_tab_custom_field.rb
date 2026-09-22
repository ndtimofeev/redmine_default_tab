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
    # Intentionally not destroying the field on a regular migration
    # rollback — that would silently wipe out every project's configured
    # tab. See README "Uninstalling" for the deliberate way to remove it.
  end
end
