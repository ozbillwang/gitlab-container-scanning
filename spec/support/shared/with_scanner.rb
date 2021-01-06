# frozen_string_literal: true
RSpec.shared_context 'with scanner' do
  # before(:all) { Docker.new(pwd: Pathname.pwd).build(tag: "gcs:latest") }

  # subject { project.report_for(type: 'container-scanning') }
  subject { runner.report_for(type: 'container-scanning') }

  # let(:docker) { Docker.new(pwd: pwd) }
  let(:pwd) { Pathname.new(File.dirname(__FILE__)).join('../../..') }
  # let(:runner) { runner.scan(env: env) }
  # let(:project) { Project.new }
  let(:project_fixture) { 'docker' }

    # let(:env) do
    #   {
    #     'DOCKERFILE_PATH' => runner.project_path.join('alpine-Dockerfile').to_s,
    #     'DOCKER_IMAGE' => 'alpine:latest'
    #   }
    # end
  # let(:env) { {} }
  # let(:command) { 'gtcs scan' }

  around do |example|
    runner.mount(dir: fixture_file(project_fixture))
    runner.scan(env: env)
    example.run
  ensure
    runner.cleanup
  end
end
