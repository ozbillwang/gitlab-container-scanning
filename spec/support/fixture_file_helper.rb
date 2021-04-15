# frozen_string_literal: true
module FixtureFileHelper
  def fixture_file(path)
    Pathname.new(__FILE__).parent.join('../fixtures', path)
  end

  def fixture_file_content(path)
    fixture_file(path).read
  end

  def fixture_file_yaml_content(path)
    YAML.safe_load(fixture_file_content(path))
  end

  def fixture_file_json_content(path)
    JSON.load(fixture_file_content(path))
  end

  def create_temporary_config_file(content, file_name)
    file = Tempfile.new(file_name)
    file.write(content.to_json)
    file.rewind

    file
  end

  def fixture_file_content(path)
    fixture_file(path).read
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
end
