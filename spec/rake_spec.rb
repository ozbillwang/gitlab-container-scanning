# frozen_string_literal: true
require 'rake'

RSpec.describe 'Rake tasks' do
  before(:all) do
    Rake.application.load_rakefile
  end

  before do
    allow(ENV).to receive(:[]).with('GITLAB_TOKEN').and_return('token')
    allow(ENV).to receive(:[]).with('CI_PROJECT_ID').and_return('123')
    allow(ENV).to receive(:[]).with('CI_COMMIT_TAG').and_return('5.0.0')
  end

  let(:changelog) { Rake::Task['changelog'] }
  let(:trigger_db_update) { Rake::Task['trigger_db_update'] }

  it 'sends api request for generating changelog' do
    req = stub_request(:post, "https://gitlab.com/api/v4/projects/123/repository/changelog")
    .to_return(status: 200, body: "", headers: {})

    changelog.invoke

    assert_requested(req)
  end

  it 'sends api request for triggering build' do
    get_req = stub_request(:get, "https://gitlab.com/api/v4/projects/123/releases")
    .with(headers: { 'Accept' => '*/*' })
    .to_return(status: 200, body: [{ 'tag_name' => '4.1.5' }].to_json, headers: {})

    post_req = stub_request(:post, 'https://gitlab.com/api/v4/projects/123/trigger/pipeline')
    .with(body: { 'ref' => "4.1.5", 'token' => 'job_token' }, headers: { 'Accept' => '*/*' })
    .to_return(status: 200, body: "", headers: {})

    allow(ENV).to receive(:[]).with('TRIGGER_DB_UPDATE').and_return(true)
    allow(ENV).to receive(:[]).with('CI_PIPELINE_SOURCE').and_return('schedule')
    allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return('job_token')

    trigger_db_update.invoke

    assert_requested(get_req)
    assert_requested(post_req)
  end
end
