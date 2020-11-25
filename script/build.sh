#!/bin/sh

set -e

case $1 in
  trivy)
     export TRIVY_VERSION=0.13.0
     echo "Dowloading Trivy"
     wget --no-verbose https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -O - | tar -zxvf -
    ;;

  gcs)
     echo "Building GCS gem"
     bundle config --local jobs "$(nproc)"
     bundle install
    ;;
  *)
     echo "everthing"
    ;;
esac
