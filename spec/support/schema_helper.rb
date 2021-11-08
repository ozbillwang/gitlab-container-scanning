# frozen_string_literal: true

module SchemaHelper
  SCHEMAS_DIR = "spec/schemas"
  SCHEMA_FILE_NAME = "container-scanning-report-format.json"

  def setup_schemas!
    return clone_schemas! unless exists?

    return if version_matches?

    clean!
    clone_schemas!
  end

  def schema_path
    Pathname.pwd.join(File.join(SCHEMAS_DIR, "dist", SCHEMA_FILE_NAME))
  end

  def exists?
    File.exist?(SCHEMAS_DIR)
  end

  def version_matches?
    json = JSON.parse(schema_path.read)
    actual_version = json.dig('self', 'version')

    actual_version == Gcs::Converter::SCHEMA_VERSION
  end

  def clean!
    FileUtils.rm_rf(SCHEMAS_DIR)
  end

  def clone_schemas!
    `git clone --depth 1 --branch "v#{Gcs::Converter::SCHEMA_VERSION}" \
      https://gitlab.com/gitlab-org/security-products/security-report-schemas.git #{SCHEMAS_DIR}`
  end
end
