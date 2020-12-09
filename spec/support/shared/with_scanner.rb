# frozen_string_literal: true

RSpec.shared_context 'with scanner' do
  before(:all) { Docker.new(pwd: Pathname.pwd).build(tag: "gcs:latest") }

  subject { project.report_for(type: 'container-scanning') }

  let(:docker) { Docker.new(pwd: pwd) }
  let(:pwd) { Pathname.new(File.dirname(__FILE__)).join('../../..') }
  let(:project) { Project.new }
  let(:project_fixture) { 'docker' }
  let(:env) { {} }
  let(:command) { 'gtcs scan' }

  around do |example|
    project.mount(dir: fixture_file(project_fixture))
    docker.run(project: project, command: command, env: env)
    example.run
  ensure
    project.cleanup
  end
end
