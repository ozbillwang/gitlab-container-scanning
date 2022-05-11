ARG SCANNER=trivy

FROM ruby:2.7-slim AS base

FROM base AS builder
ENV PATH="/gcs/:${PATH}"
RUN apt-get update && apt-get install -y -q build-essential && rm -rf /var/lib/apt/lists/*

RUN mkdir /gcs
WORKDIR /gcs

COPY Gemfile Gemfile.lock gcs.gemspec ./
COPY lib/gcs/version.rb lib/gcs/version.rb
RUN bundle install --jobs 20 --retry 5

COPY . ./

SHELL ["/bin/bash", "-c"]
RUN gem build gcs.gemspec -o gcs.gem


FROM base
ARG ORAS_URL=https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/package_files/29703212/download
ARG SCANNER
ENV SCANNER=${SCANNER}
ARG EE
ENV EE=${EE}
ENV PATH="/home/gitlab:${PATH}"

RUN useradd --create-home gitlab -g root

COPY --from=builder --chown=gitlab:root /gcs/gcs.gem /gcs/script/setup.sh /gcs/version /home/gitlab/

RUN apt-get update && apt-get upgrade -y && apt-get install -y -q \
  wget \
  curl \
  unzip \
  ca-certificates \
  git-core \
  sudo && \
  wget ${ORAS_URL} -O /usr/local/bin/oras && chmod +x /usr/local/bin/oras && \
  chown gitlab /usr/local/share/ca-certificates /usr/lib/ssl/certs/ && \
  chmod -R g+rw /usr/local/share/ca-certificates/ /usr/lib/ssl/certs/ && \
  echo "gitlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitlab && \
  gem install --no-document /home/gitlab/gcs.gem && \
  su - gitlab -c "export SCANNER=$SCANNER EE=$EE PATH="/home/gitlab:${PATH}"; cd /home/gitlab && bash setup.sh" && \
  rm -f /usr/local/bin/oras && \
  apt-get remove -y curl wget xauth openssh-client && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /var/cache/debconf/templates.* /var/lib/dpkg/status-old

USER gitlab
ENV HOME "/home/gitlab"

WORKDIR /home/gitlab
CMD ["gtcs", "scan"]
