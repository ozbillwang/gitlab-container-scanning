# frozen_string_literal: true

module TagRelease
  def prompt!
    print "Continue? [Y/n]: "
    confirm = $stdin.gets.chomp
    exit unless confirm.casecmp("y").zero?
  end

  def previous_version
    f = File.open("CHANGELOG.md", "r")
    changelog = f.read
    f.close

    changelog.match(/^## (\d+\.\d+\.\d+)/).captures.first
  end
end
