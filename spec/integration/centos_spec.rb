# frozen_string_literal: true

RSpec.describe 'centos' do
  let(:env) do
    {
      'DOCKERFILE_PATH' => runner.project_path.join('centos8-Dockerfile').to_s,
      'DOCKER_IMAGE' => 'centos:centos8',
      'DOCKER_USER' => '',
      'DOCKER_PASSWORD' => ''
    }
  end

  let(:project_fixture) { fixture_file('docker/centos_project') }

  context 'when scanning an Centos based image', integration: :centos do
    include_examples 'as container scanner'
  end

  context 'when grype reports package vulnerabilities', integration: :centos, if: ENV['SCANNER'] == 'grype' do
    include_context 'with scanner'

    it 'is less than reported count' do
      # centos8 has 222 OS and package vulnerabilities but only 2 of them are OS based.
      stdout, _, _ = Open3.capture3("grype registry:centos:centos8 | wc -l")
      package_vulnerabilities_count = stdout.to_i - 1

      expect(report['vulnerabilities'].count).to be < package_vulnerabilities_count
    end
  end
end
