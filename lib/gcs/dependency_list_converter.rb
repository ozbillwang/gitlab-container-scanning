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
      parsed_report = JSON.parse(@source) unless @source.nil?

      converted_report['scan']['start_time'] = @opt.fetch(:start_time, '')
      converted_report['scan']['end_time'] = @opt.fetch(:end_time, '')

      converted_report['version'] = Gcs::Converter::SCHEMA_VERSION
      converted_report['scan']['analyzer']['version'] = Gcs::VERSION

      return converted_report if parsed_report.nil?

      os_family = parsed_report.dig('Metadata', 'OS', 'Family')
      os_version = parsed_report.dig('Metadata', 'OS', 'Name')

      repo_tag = parsed_report.dig('Metadata', 'RepoTags', 0)
      repo_digest = parsed_report.dig('Metadata', 'RepoDigests', 0)

      converted_report['dependency_files'] << {
        'path' => "#{CONTAINER_IMAGE_PREFIX}#{repo_tag || repo_digest}",
        'package_manager' => "#{os_family}:#{os_version} (#{package_manager_name(os_family)})",
        'dependencies' => convert_dependencies(parsed_report['Results'])
      }

      converted_report
    end

    private

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

    def convert_dependencies(results)
      results
        .select { |result| result['Class'] == 'os-pkgs' }
        .flat_map do |result|
          result['Packages'].map do |package|
            {
              'package' => {
                'name' => package['SrcName']
              },
              'version' => package['SrcVersion']
            }
          end
        end
    end
  end
end
