#!/bin/sh

set -e

function download_trivy() {
  export TRIVY_VERSION=0.13.0
  echo "Dowloading Trivy"
  wget --no-verbose https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -O - | tar -zxvf -
  chmod +x trivy
}

function download_trivy_db() {
  echo "Dowloading Trivy DB"
  trivy image --download-db-only
}

function build_gem() {
  echo "Building gem"
  gem build -o gcs.gem
}

case $1 in
trivy)
  download_trivy
  download_trivy_db
  ;;

gem)
  build_gem
  ;;
*)
  download_trivy
  download_trivy_db
  build_gem
  ;;
esac