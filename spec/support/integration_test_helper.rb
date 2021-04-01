module IntegrationTestHelper
  def runner(*args)
    @runner ||= ProjectHelper.new(*args)
  end
end

class ProjectHelper
  include Helpers
  attr_reader :project_path, :virtual_path

  def initialize(project_path = Pathname.pwd.join('tmp').join(SecureRandom.uuid))
    FileUtils.mkdir_p(project_path)
    @project_path = Pathname(project_path)
    @virtual_path = Pathname("/tmp/app")
  end

  def report_for(type:)
    report_path = project_path.join("gl-#{type}-report.json")

    if report_path.exist?
      JSON.parse(report_path.read)
    else
      puts "Report not found in: #{report_path}"
      puts project_path.glob('*')
      {}
    end
  end

  def add_file(name, content = nil)
    full_path = project_path.join(name)
    FileUtils.mkdir_p(full_path.dirname)
    IO.write(full_path, block_given? ? yield : content)
  end

  def mount(dir:, add_allow_list: false)
    if add_allow_list
      FileUtils.cp_r(fixture_file('vulnerability-allowlist.yml'), project_path)
    end
    FileUtils.cp_r("#{dir}/.", project_path)
  end

  def chdir
    puts "changing directory to #{project_path}"
    Dir.chdir project_path do
      yield
    end
  end

  def clone(repo, branch: 'master')
    if branch.match?(/\b[0-9a-f]{5,40}\b/)
      execute({}, 'git', 'clone', '--quiet', repo, project_path.to_s)
      chdir do
        execute({}, 'git', 'checkout', branch)
      end
    else
      execute({}, 'git', 'clone', '--quiet', '--depth=1', '--single-branch', '--branch', branch, repo, project_path.to_s)
    end
  end

  def scan(env: {})
    chdir do
      expanded_env = {
        'CI_PROJECT_DIR' => project_path.to_s,
        'CONSOLE_LEVEL' => 'debug',
        'RUBYOPT' => "-I#{Gcs.lib}",
      }.merge(env)
      return {} unless execute(expanded_env, "#{Gcs.lib.join('../exe/gtcs')} scan")

      report_path = project_path.join('gl-container-scanning-report.json')
      return {} unless report_path.exist?
    end
  end

  def execute(env = {}, *args)
    Bundler.with_unbundled_env do
      system(env, *args, exception: true)
    end
  end

  def cleanup
    FileUtils.rm_rf(project_path) if project_path.exist?
  end
end
