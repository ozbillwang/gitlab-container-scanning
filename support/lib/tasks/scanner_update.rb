# frozen_string_literal: true

require_relative 'status'

class ScannerUpdate
  VERSION_FILE_PATH = 'version/'
  GEMFILE_LOCK_PATH = 'Gemfile.lock'
  FIXTURES_DIR_PATH = 'spec/fixtures/converter/expect/*'
  SCANNERS = {
    trivy: {
      uri: 'https://api.github.com/repos/aquasecurity/trivy/releases/latest',
      changelog_uri: 'https://github.com/aquasecurity/trivy/releases/tag/v%{version}',
      template: Gcs::Trivy.template_file,
      dependencies_template: Gcs::Trivy.dependencies_template_file
    },
    grype: {
      uri: 'https://api.github.com/repos/anchore/grype/releases/latest',
      changelog_uri: 'https://github.com/anchore/grype/releases/tag/v%{version}',
      template: Gcs::Grype.template_file,
      dependencies_template: Gcs::Grype.dependencies_template_file
    }
  }.freeze

  def initialize(scanner)
    @scanner = scanner.to_sym
  end

  def changelog_link(version)
    format(SCANNERS[@scanner][:changelog_uri], { version: version })
  end

  def version_file
    File.join(VERSION_FILE_PATH, "#{@scanner.upcase}_VERSION")
  end

  def current_version
    File.read(version_file).strip
  end

  def versions
    uri = URI(SCANNERS[@scanner][:uri])
    res = Net::HTTP.get_response(uri)
    abort("Can't get latest #{@scanner} release from Github") unless res.code == '200'
    res = JSON.parse(res.body) # e.g.  "tag_name": "v0.19.1"
    [res['tag_name'][1..], current_version]
  end

  def check_versions(new, old)
    Status.done("#{@scanner} version has not changed: #{new}") unless new != old
    abort("#{@scanner} new version format not recognized: #{new}") unless new.match?(/\d+\.\d+\.\d+/)
  end

  def update_scanner(bump_version: false)
    new_version, current_version = versions
    check_versions(new_version, current_version)

    puts "Version has changed from #{current_version} to #{new_version}"
    branch_name = "update-#{@scanner}-to-#{new_version}-#{Date.today}"
    puts "Creating #{branch_name} branch"

    git('checkout', '-b', branch_name)

    File.truncate(version_file, 0)
    File.write(version_file, new_version)

    new_content = File.read(SCANNERS[@scanner][:template])
                      .sub(/.*[\s\S]*\K"version": "#{current_version}"/, "\"version\": \"#{new_version}\"")

    File.open(SCANNERS[@scanner][:template], 'w') do |out|
      out << new_content
    end

    update_version_in_template_or_fixture(SCANNERS[@scanner][:dependencies_template], new_scanner_version: new_version)

    if bump_version
      new_gem_version = bump_patch_version

      update_version_rb(new_gem_version)
      update_gemfile_lock(new_gem_version)
      update_fixtures(new_gem_version)

      git('add', version_rb_path)
      git('add', GEMFILE_LOCK_PATH)
    end

    git('add', version_file)
    git('add', SCANNERS[@scanner][:template])

    git('commit', '-m', "Update #{@scanner} to version #{new_version}\n\nChangelog: changed")
  end

  def bump_patch_version
    major, minor, patch = Gem::Version.new(Gcs::VERSION).segments
    patch += 1
    "#{major}.#{minor}.#{patch}"
  end

  def update_version_in_template_or_fixture(template_or_fixture_file, new_scanner_version: nil, new_gem_version: nil)
    template_or_fixture = JSON.parse(File.read(template_or_fixture_file))
    template_or_fixture['scan']['scanner']['version'] = new_scanner_version unless new_scanner_version.nil?
    template_or_fixture['scan']['analyzer']['version'] = new_gem_version unless new_gem_version.nil?
    File.open(template_or_fixture_file, 'w') { |file| file.write(JSON.pretty_generate(template_or_fixture)) }

    git('add', template_or_fixture_file)
  end

  def update_version_rb(new_version)
    new_content = File.read(version_rb_path)
                      .sub(/.*[\s\S]*\KVERSION = "#{Gcs::VERSION}"/o, "VERSION = \"#{new_version}\"")

    File.open(version_rb_path, 'w') { |file| file.write(new_content) }
  end

  def version_rb_path
    @version_rb_path ||= File.join(Gcs.lib, 'gcs', 'version.rb').to_s
  end

  def update_gemfile_lock(new_version)
    new_content = File.read(GEMFILE_LOCK_PATH)
                      .sub(/.*[\s\S]*\Kgcs \(\d+\.\d+\.\d+\)/o, "gcs (#{new_version})")

    File.open(GEMFILE_LOCK_PATH, 'w') { |file| file.write(new_content) }
  end

  def update_fixtures(new_version)
    Dir[FIXTURES_DIR_PATH].each do |file|
      update_version_in_template_or_fixture(file, new_gem_version: new_version)
    end
  end
end
