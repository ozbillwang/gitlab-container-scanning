# frozen_string_literal: true
require 'net/http'
require 'json'

class GitlabClient
  CURRENT_USER_URL = "https://gitlab.com/api/v4/user"

  def initialize(project_id:, gitlab_token:)
    @project_id = project_id
    @gitlab_token = gitlab_token
  end

  def self.ci
    @ci ||= new(
      project_id: ENV['CI_PROJECT_ID'],
      gitlab_token: ENV['CS_TOKEN']
    )
  end

  def inspect
    # Prevent token from being printed
    "#<#{self.class} project_id=#{@project_id}>"
  end

  def configured?
    @project_id.present? && @gitlab_token.present? && authenticated?
  end

  def generate_changelog(version)
    post(changelog_uri, form_data: { version: version })
  end

  def releases
    get(releases_uri)
  end

  def latest_release
    res = releases
    unless res.code == '200'
      puts "Failed to get releases (status #{res.code}): #{res.body}"
      return
    end

    ::JSON.parse(res.body).first['tag_name']
  end

  def trigger_pipeline(ref)
    post(trigger_pipeline_uri(ref))
  end

  private

  def authenticated?
    res = get(URI(CURRENT_USER_URL))
    authenticated = res.code == '200'
    puts "Failed to authenticate to GitLab (status #{res.code}): #{res.body}" unless authenticated
    authenticated
  end

  def get(uri)
    req = ::Net::HTTP::Get.new(uri)
    send_req(req)
  end

  def post(uri, form_data: {})
    req = ::Net::HTTP::Post.new(uri)
    req.set_form_data(**form_data) if form_data
    send_req(req)
  end

  def send_req(req)
    add_headers!(req)
    ::Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  end

  def add_headers!(req)
    req['PRIVATE-TOKEN'] = @gitlab_token
    req['Content-Type'] = 'application/json'
  end

  def projects_url
    @projects_url ||= "https://gitlab.com/api/v4/projects/#{@project_id}"
  end

  def changelog_uri
    @changelog_url ||= URI("#{projects_url}/repository/changelog")
  end

  def releases_uri
    @releases_url ||= URI("#{projects_url}/releases")
  end

  def trigger_pipeline_uri(ref)
    encoded = ::URI.encode_www_form_component(ref)
    URI("#{projects_url}/pipeline?ref=#{encoded}")
  end
end
