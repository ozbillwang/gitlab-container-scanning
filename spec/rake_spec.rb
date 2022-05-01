# frozen_string_literal: true
require 'rake'

RSpec.describe 'Rake tasks' do
  before(:all) do
    Rake.application.load_rakefile
  end

  modify_environment 'CS_TOKEN' => 'token',
                     'CI_PROJECT_ID' => '123',
                     'CI_COMMIT_TAG' => '5.0.0',
                     'TRIGGER_DB_UPDATE_FOR_MAJOR_VERSIONS' => '4',
                     'CI_PIPELINE_SOURCE' => 'schedule',
                     'CI_JOB_TOKEN' => 'job_token',
                     'CI_PROJECT_PATH' => 'some_group/some_project'

  before do
    stub_request(:get, "https://gitlab.com/api/v4/user")
    .with(
      headers: {
        'Content-Type' => 'application/json',
        'Private-Token' => 'token'
      })
    .to_return(status: 200, body: "", headers: {})
  end

  let(:changelog) { Rake::Task['changelog'] }
  let(:trigger_db_update) { Rake::Task['trigger_db_update'] }

  it 'sends api request for generating changelog' do
    req = stub_request(:post, "https://gitlab.com/api/v4/projects/123/repository/changelog")
    .with(
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Private-Token' => 'token'
      })
    .to_return(status: 200, body: "", headers: {})

    changelog.invoke

    assert_requested(req)
  end

  it 'sends api request for triggering build' do
    graphql_response = %(
      { "data": { "project": { "releases": { "nodes": [
          { "tagName": "3.4.5" },
          { "tagName": "4.1.5" },
          { "tagName": "4.1.6" },
          { "tagName": "5.6.7" }
        ] } } } }
      )

    graphql_req = stub_request(:post, "https://gitlab.com/api/graphql")
      .with(
        body: { "query" => "query {\n        project(fullPath:\"some_group/some_project\") {\n          " \
                "releases(first:100, sort: RELEASED_AT_DESC) {\n            nodes {\n              " \
                "tagName\n            }\n          }\n        }\n      }" },
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Private-Token' => 'token'
        })
      .to_return(status: 200, body: graphql_response, headers: {})

    post_req = stub_request(:post, 'https://gitlab.com/api/v4/projects/123/pipeline?ref=4.1.5')
    .with(
      body: {},
      headers: {
        'Accept' => '*/*',
        'Content-Type' => 'application/json',
        'Private-Token' => 'token'
      })
    .to_return(status: 200, body: '{"web_url": "some_url"}', headers: {})

    trigger_db_update.invoke

    assert_requested(graphql_req)
    assert_requested(post_req)
  end
end
