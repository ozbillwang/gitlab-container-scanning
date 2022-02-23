#!/bin/sh

set -e

setup_trivy_files() {
  echo "Creating temp directory"
  TMP_FOLDER=$(mktemp -d)
  trivy_version=$(cat TRIVY_VERSION)
  trivy_db_version=$(cat TRIVY_DB_VERSION)
  echo "Dowloading and installing Trivy ${trivy_version}"
  wget --no-verbose https://github.com/aquasecurity/trivy/releases/download/v"${trivy_version}"/trivy_"${trivy_version}"_Linux-64bit.tar.gz -O - | tar -zxvf -
  echo "Dowloading Trivy DB"
  oras pull ghcr.io/aquasecurity/trivy-db:"${trivy_db_version}" -a && tar -zxvf db.tar.gz -C "$TMP_FOLDER"
  rm -f db.tar.gz
  echo "Setting up Trivy files"
  mkdir -p /home/gitlab/.cache/trivy/db
  mv "$TMP_FOLDER"/trivy.db "$TMP_FOLDER"/metadata.json /home/gitlab/.cache/trivy/db/
  chmod -R g+rw /home/gitlab/.cache/
  echo "Cleaning up tmp folder"
  rm -rf "$TMP_FOLDER"
}

download_grype() {
  grype_version=$(cat GRYPE_VERSION)
  echo "Dowloading and installing Grype ${grype_version}"
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /home/gitlab "v${grype_version}"
}

download_grype_db() {
  echo "Downloading Grype database"
  grype db check -v
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
