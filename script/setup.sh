#!/bin/sh

set -e

CE_TRIVY_DB_REGISTRY="ghcr.io/aquasecurity/trivy-db"
EE_TRIVY_DB_REGISTRY="registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-db-glad"

setup_trivy_files() {
  echo "Creating temp directory"
  trivy_version=$(cat TRIVY_VERSION)
  trivy_db_version_ce=$(cat TRIVY_DB_VERSION_CE)
  trivy_db_version_ee=$(cat TRIVY_DB_VERSION_EE)
  echo "Dowloading and installing Trivy ${trivy_version}"
  mkdir /home/gitlab/opt/trivy
  wget --no-verbose https://github.com/aquasecurity/trivy/releases/download/v"${trivy_version}"/trivy_"${trivy_version}"_Linux-64bit.tar.gz -O - | tar -zxvf - -C /home/gitlab/opt/trivy
  ln -s /home/gitlab/opt/trivy/trivy /home/gitlab/trivy

  echo "Setting up Trivy files"
  mkdir -p /home/gitlab/.cache/trivy/ce/db /home/gitlab/.cache/trivy/ee/db
  rm -rf /home/gitlab/legal/grype
  mv /home/gitlab/legal /home/gitlab/.cache/trivy

  echo "Dowloading CE Trivy DB"
  oras pull "$CE_TRIVY_DB_REGISTRY":"${trivy_db_version_ce}" -a && tar -zxvf db.tar.gz -C /home/gitlab/.cache/trivy/ce/db
  rm -f db.tar.gz

  echo "Dowloading EE Trivy DB"
  oras pull "$EE_TRIVY_DB_REGISTRY":"${trivy_db_version_ee}" -a && tar -zxvf db.tar.gz -C /home/gitlab/.cache/trivy/ee/db
  rm -f db.tar.gz

  chmod -R g+rw /home/gitlab/.cache/
}

download_grype() {
  grype_version=$(cat GRYPE_VERSION)
  echo "Dowloading and installing Grype ${grype_version}"
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /home/gitlab/opt/grype "v${grype_version}"
  ln -s /home/gitlab/opt/grype/grype /home/gitlab/grype
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
  rm -rf /home/gitlab/legal/glad /home/gitlab/legal/trivy-db
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

mkdir /home/gitlab/opt
select_scanner
