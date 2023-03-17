# frozen_string_literal: true

module Gcs
  class DependencyListConverter
    CONTAINER_IMAGE_PREFIX = 'container-image:'

    def initialize(template, source = nil, opt = {})
      @template = template
      @source = source
      @opt = opt
    end

    def convert
      converted_report = JSON.parse(@template)

      converted_report['scan']['start_time'] = @opt.fetch(:start_time, '')
      converted_report['scan']['end_time'] = @opt.fetch(:end_time, '')

      converted_report['version'] = Gcs::Converter.schema_version
      converted_report['scan']['analyzer']['version'] = Gcs::VERSION

      return converted_report if @source.nil?

      parsed_report = JSON.parse(@source)

      return converted_report if parsed_report['Results'].blank?

      os_family = parsed_report.dig('Metadata', 'OS', 'Family')
      os_version = parsed_report.dig('Metadata', 'OS', 'Name')

      repo_tag = parsed_report.dig('Metadata', 'RepoTags', 0)
      repo_digest = parsed_report.dig('Metadata', 'RepoDigests', 0)

      container_image_path = "#{CONTAINER_IMAGE_PREFIX}#{repo_tag || repo_digest}"

      converted_report['dependency_files'] = filter_results(parsed_report['Results']).map do |result|
        {
          'path' => container_image_path,
          'package_manager' => package_manager(os_family, os_version, result),
          'dependencies' => convert_dependencies(result.fetch('Packages', []))
        }
      end

      converted_report
    end

    private

    def package_manager(os_family, os_version, result)
      # "alpine:3.15.0 (apk)"
      return "#{os_family}:#{os_version} (#{package_manager_name(os_family)})" if os_package?(result)

      # "Java (jar)"
      "#{result['Target']} (#{result['Type']})"
    end

    def package_manager_name(os_family)
      case os_family&.downcase
      when 'alpine' then 'apk'
      when 'debian', 'ubuntu' then 'apt'
      when 'amazon', 'oracle', 'centos', 'redhat' then 'yum'
      when 'photon' then 'tdnf'
      when /suse/ then 'zypper'
      else 'unknown'
      end
    end

    def os_package?(result)
      result['Class'] == 'os-pkgs'
    end

    def filter_results(results)
      return results unless Gcs::Environment.language_specific_scan_disabled?

      results.select { |result| os_package?(result) }
    end

    def convert_dependencies(packages)
      packages.map do |package|
        {
          'package' => {
            'name' => package['SrcName'] || package['Name']
          },
          'version' => package['SrcVersion'] || package['Version']
        }
      end
    end
  end
end
