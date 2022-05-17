# frozen_string_literal: true

class GenerateConverterFixtures
  CONVERTER_OPTS = { start_time: "2021-09-15T08:36:08", end_time: "2021-09-15T08:36:25" }.freeze
  CONVERTER_FIXTURES_PATH = ::File.join('spec', 'fixtures', 'converter')

  class << self
    def execute
      fixture_file_paths.each do |path|
        puts "Generating expectations for #{path}"
        gitlab_format = convert_from_file(path)
        write(gitlab_format, expectation_file_path(path))
      end

      puts "Done"
    end

    private

    def fixture_file_paths
      ::Dir.glob(::File.join(CONVERTER_FIXTURES_PATH, 'scanner_output', '*.json'))
    end

    def convert_from_file(path)
      scanner_output = ::File.open(path).read

      opts = CONVERTER_OPTS
      opts = opts.merge(image_name: 'g:0.1') if path == 'spec/fixtures/converter/scanner_output/trivy-with-language.json'

      ENV['CS_DEFAULT_BRANCH_IMAGE'] = 'registry.example.com/group/project:latest'

      ::Gcs::Converter.new(scanner_output, opts).convert
    end

    def expectation_file_path(scanner_output_file_path)
      basename = ::Pathname.new(scanner_output_file_path).basename
      ::File.join(CONVERTER_FIXTURES_PATH, 'expect', basename)
    end

    def write(gitlab_format, path)
      raw = ::JSON.pretty_generate(gitlab_format, { indent: '  ' })
      ::File.write(path, raw)
      puts "Wrote new expectation to #{path}"
    end
  end
end
