# frozen_string_literal: true

class Project
  attr_reader :path, :virtual_path

  def initialize(path = Pathname.pwd.join('tmp').join(SecureRandom.uuid))
    FileUtils.mkdir_p(path)
    @path = Pathname(path)
    @virtual_path = Pathname("/tmp/app")
  end

  def report_for(type:)
    report_path = path.join("gl-#{type}-report.json")

    if report_path.exist?
      JSON.parse(report_path.read)
    else
      puts "Report not found in: #{path}"
      puts path.glob('*')
      {}
    end
  end

  def mount(dir:)
    FileUtils.cp_r("#{dir}/.", path)
  end

  def chdir(&block)
    Dir.chdir path, &block
  end

  def cleanup = FileUtils.rm_rf(path) if path.exist?
end
