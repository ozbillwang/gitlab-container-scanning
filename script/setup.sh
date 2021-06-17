#!/bin/sh

set -e

setup_trivy_files() {
  echo "Dowloading Trivy"
  trivy_version=$(cat TRIVY_VERSION)
  wget --no-verbose https://github.com/aquasecurity/trivy/releases/download/v"${trivy_version}"/trivy_"${trivy_version}"_Linux-64bit.tar.gz -O - | tar -zxvf -
  echo "Dowloading Trivy DB"
  wget --no-verbose https://github.com/aquasecurity/trivy-db/releases/latest/download/trivy-offline.db.tgz -O - | tar -zxvf - -C /tmp/
  echo "Setting up Trivy files"
  mkdir -p ~/.cache/trivy/db
  mv /tmp/trivy.db /tmp/metadata.json ~/.cache/trivy/db/
  chmod -R g+rw /home/gitlab/.cache/
  echo "Cleaning up tmp folder"
  rm -f /tmp/*
}

download_grype() {
  echo "Dowloading Grype"
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /home/gitlab v0.13.0
}

download_grype_db() {
  echo "Downloading Grype database"
  grype db update -v
}

setup_grype_files() {
  echo "Setting up Grype files"
  download_grype
  download_grype_db
}

select_scanner() {
  # The following conditionals will have be update to accomodate a new scanner.
  # Note that files under download folder are coming from the previous docker stage.
  # The default should always point to trivy
  lower_case=$(echo "${SCANNER}" | tr '[:upper:]' '[:lower:]')
  if [ -n "${lower_case}" ] && [ "${lower_case}" = grype ]; then
    setup_grype_files
  else
    setup_trivy_files
  fi
}

select_scanner
