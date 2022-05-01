# frozen_string_literal: true
require 'net/http'
require 'json'

class GitlabClient
  CURRENT_USER_URL = "https://gitlab.com/api/v4/user"
  GRAPHQL_URL = 'https://gitlab.com/api/graphql'

  def initialize(project_id:, gitlab_token:, project_path:)
    @project_id = project_id
    @gitlab_token = gitlab_token
    @project_path = project_path
  end

  def self.ci
    @ci ||= new(
      project_id: ENV['CI_PROJECT_ID'],
      gitlab_token: ENV['CS_TOKEN'],
      project_path: ENV['CI_PROJECT_PATH']
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
    res = post(changelog_uri, form_data: { version: version })

    generic_result(res)
  end

  def list_available_group_member_usernames(group_id = ENV['CS_REVIEWERS_GROUP_ID'])
    if group_id.blank?
      puts "Failed to get group members (group_id is not set)"
      return []
    end

    res = get(group_members_uri(group_id))

    unless res.code == '200'
      puts "Failed to get group members (status #{res.code}): #{res.body}"
      return []
    end

    ::JSON
      .parse(res.body)
      .select { |member| user_available?(member['username']) }
      .map { |member| "@#{member['username']}" }
  end

  def user_available?(username)
    res = get(user_status_uri(username))

    unless res.code == '200'
      puts "Failed to get user status (status #{res.code}): #{res.body}"
      return false
    end

    ::JSON.parse(res.body)['availability'] != 'busy'
  end

  def list_mrs(search)
    res = get(merge_requests_search_uri(search))
    unless res.code == '200'
      puts "Failed to get merge requests (status #{res.code}): #{res.body}"
      return []
    end

    ::JSON.parse(res.body)
  end

  def mr_exists?(title)
    list_mrs(title).present?
  end

  def create_mr(title:, description:, source_branch:, target_branch: 'master')
    data = {
      source_branch: source_branch,
      target_branch: target_branch,
      title: title,
      description: description,
      remove_source_branch: true,
      squash: true
    }
    res = post(merge_requests_uri, form_data: data)

    if res.code == '201'
      { status: :success, code: res.code, web_url: ::JSON.parse(res.body)['web_url'] }
    else
      { status: :failure, code: res.code, message: res.body }
    end
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
    res = post(trigger_pipeline_uri(ref))

    generic_result(res)
  end

  def latest_releases_for(major_versions)
    response = []
    major_versions.split(',').compact.map(&:strip).each do |major|
      latest_releases.each do |release_version|
        release_version_major, _, _ = Gem::Version.new(release_version).segments

        next if release_version_major.to_s != major
        next if major_version_included?(response, major)

        response << release_version
      end
    end

    response
  end

  def latest_releases
    @latest_releases ||= begin
      query = %(query {
        project(fullPath:"#{@project_path}") {
          releases(first:100, sort: RELEASED_AT_DESC) {
            nodes {
              tagName
            }
          }
        }
      })

      res = graphql(query)
      if res.code == '200'
        nodes = ::JSON.parse(res.body).dig('data', 'project', 'releases', 'nodes')
        nodes.map { |x| x['tagName'] }
      else
        puts "Failed to get releases (status #{res.code}): #{res.body}"
        []
      end
    end
  end

  private

  def major_version_included?(response, major)
    response.map { |x| Gem::Version.new(x).segments.first.to_s }.include?(major)
  end

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
    req.set_form_data(**form_data) unless form_data.empty?
    send_req(req)
  end

  def generic_result(res)
    code = res.code.to_i

    return { status: :success, code: code, message: res.body } if code >= 200 && code < 300

    { status: :failure, code: code, message: res.body }
  end

  def send_req(req)
    add_headers!(req)
    ::Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  end

  def add_headers!(req)
    req['PRIVATE-TOKEN'] = @gitlab_token
    req['Content-Type'] = 'application/json' unless req['Content-Type']
  end

  def groups_url(group_id)
    "https://gitlab.com/api/v4/groups/#{group_id}"
  end

  def group_members_uri(group_id)
    URI("#{groups_url(group_id)}/members")
  end

  def user_status_uri(username)
    URI("https://gitlab.com/api/v4/users/#{username}/status")
  end

  def projects_url
    @projects_url ||= "https://gitlab.com/api/v4/projects/#{@project_id}"
  end

  def merge_requests_uri
    @merge_requests_uri ||= URI("#{projects_url}/merge_requests")
  end

  def merge_requests_search_uri(search)
    encoded = ::URI.encode_www_form_component(search)
    URI("#{merge_requests_uri}?search=#{encoded}")
  end

  def changelog_uri
    @changelog_uri ||= URI("#{projects_url}/repository/changelog")
  end

  def releases_uri
    @releases_uri ||= URI("#{projects_url}/releases")
  end

  def trigger_pipeline_uri(ref)
    encoded = ::URI.encode_www_form_component(ref)
    URI("#{projects_url}/pipeline?ref=#{encoded}")
  end

  def graphql(query)
    post(URI(GRAPHQL_URL), form_data: { 'query' => query })
  end
end
