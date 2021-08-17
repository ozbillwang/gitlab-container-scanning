# frozen_string_literal: true
require 'open3'

DEFAULT_BRANCH_NAME = "master"

def git(cmd, *args)
  output, status = Open3.capture2e('git', cmd, *args)

  abort "Failed to run `git #{cmd}`: #{output}" unless status.success?

  output.strip
end

def default_branch? = current_branch == DEFAULT_BRANCH_NAME

def current_branch
  git_branch_output = git('branch')
  line = git_branch_output.lines.find { |line| line.start_with? "* " }
  line.delete_prefix("* ").delete_suffix("\n")
end
