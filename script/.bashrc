#!/bin/bash -l

# inflate extracts a given tar.gz archive to a given directory.
# It removes the file and is a no-op after being executed.
function inflate() {
  local file=$1
  local to_dir=$2
  if [ -f "$file" ]; then
    tar -xzf "$file" -C "$to_dir"
    rm "$file"
  fi
}

# inflate trivy db files (if they exist)
inflate /tmp/trivy-ce/db.tar.gz /home/gitlab/.cache/trivy/ce/db
inflate /tmp/trivy-ee/db.tar.gz /home/gitlab/.cache/trivy/ee/db

# inflate grype db file (if it exists)
inflate /home/gitlab/.cache/grype/db.tgz /home/gitlab/.cache/grype/
