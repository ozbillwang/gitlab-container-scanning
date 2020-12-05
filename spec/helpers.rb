# frozen_string_literal: true

module Helpers
  def fixture_file(path)
    Pathname.new(__FILE__).parent.join('fixtures', path)
  end

  def default_config
    { 'skip' => {}, 'update' => { 'default' => 'minor', 'major' => {}, 'minor' => {}, 'patch' => {} } }
  end

  def create_temporary_config_file(content = default_config)
    file = Tempfile.new('config.json')
    file.write(content.to_json)
    file.rewind

    file
  end

  def fixture_file_content(path)
    fixture_file(path).read
  end

  def license_file(id)
    fixture_file_content("spdx/text/#{id}.txt")
  end

  def to_path(path)
    Pathname.new(path)
  end

  def within_tmp_dir
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        yield Pathname.new(directory)
      end
    end
  end

  class IOMock
    def initialize(response = [])
      @response = response
    end

    def each_line
      @response.each do |value|
        yield value
      end
    end
  end
end
