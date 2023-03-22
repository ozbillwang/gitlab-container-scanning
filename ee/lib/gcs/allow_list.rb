# frozen_string_literal: true

module Gcs
  class AllowList
    ALLOW_LIST_FILENAME = 'vulnerability-allowlist.yml'

    def initialize(allow_list_file_path = AllowList.file_path)
      @allow_list = YAML.load_file(allow_list_file_path)
      @allow_list_cve = allow_list_cve
    end

    def allowed?(vuln)
      cve = vuln['identifiers'].find { |identifier| identifier['type'].casecmp("cve").zero? }&.dig('value')
      return false unless cve

      docker_image = vuln.dig('location', 'image')&.gsub(/\s\S*/, '')

      included_in_general?(cve) || included_in_images?(cve, docker_image)
    end

    private

    def allow_list_cve
      {
        general: @allow_list&.[]("generalallowlist"),
        images: @allow_list&.[]("images")
      }
    end

    def included_in_general?(cve)
      return false unless @allow_list_cve[:general]

      @allow_list_cve[:general].key?(cve)
    end

    def included_in_images?(cve, docker_image)
      return false unless @allow_list_cve[:images] && docker_image

      image = @allow_list_cve[:images].keys.find { |key| docker_image.include?(key) }
      !!@allow_list_cve.dig(:images, image)&.key?(cve)
    end

    def self.file_path
      File.join(Gcs::Environment.project_dir.to_s, ALLOW_LIST_FILENAME)
    end
  end
end
