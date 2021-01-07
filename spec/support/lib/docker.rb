# frozen_string_literal: true

class Docker
  DEFAULT_ENV = {
    'CI_DEBUG_TRACE' => 'true',
    'CI_PROJECT_DIR' => '/tmp/app',
    'SECURE_LOG_LEVEL' => 'debug'
  }.freeze
  DEFAULT_IMAGE_NAME = 'gcs:latest'.freeze

  attr_reader :pwd

  def initialize(pwd: Pathname.pwd)
    @pwd = pwd
  end

  def build(tag:)
    Dir.chdir pwd do
      if ENV['CI']
        cmd = "docker build -t #{ENV.fetch('IMAGE_TAG', tag)} ."
      else
        cmd = "docker build -t #{tag} ."
        ENV['IMAGE_TAG'] = tag
      end
      system(cmd, exception: true)
    end
  end

  def run(project:, env: {}, command:)
    env_options = DEFAULT_ENV.merge(env).map { |(key, value)| "--env #{key}='#{value}'" }
    Dir.chdir pwd do
      arguments = [
        :docker, :run, '--rm',
        "--entrypoint=/bin/sh",
        "--volume=#{project.path}:#{project.virtual_path}",
        "--workdir=#{project.virtual_path}",
        env_options
      ]
      arguments.push(ENV.fetch('IMAGE_TAG', DEFAULT_IMAGE_NAME))
      arguments.push("-c '#{command}'") if command
      system(expand(arguments), exception: true)
    end
  end

  private

  def expand(command)
    command.flatten.map(&:to_s).join(' ')
  end
end
