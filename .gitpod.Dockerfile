FROM ruby:2.7-slim

USER root

# Install OS dependencies
RUN apt-get update && apt-get install -y -q build-essential wget curl unzip ca-certificates git-core sudo wget apt-transport-https gnupg lsb-release && rm -rf /var/lib/apt/lists/*

# Install trivy
COPY version/TRIVY_VERSION /tmp/TRIVY_VERSION
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v$(cat /tmp/TRIVY_VERSION)

# Install grype
COPY version/GRYPE_VERSION /tmp/GRYPE_VERSION
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin v$(cat /tmp/GRYPE_VERSION)
