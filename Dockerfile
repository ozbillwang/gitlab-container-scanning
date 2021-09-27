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
ARG SCANNER
ENV SCANNER=${SCANNER}
ENV PATH="/home/gitlab:${PATH}"

RUN apt-get update && apt-get upgrade -y && apt-get install -y -q \
  wget \
  curl \
  ca-certificates \
  git-core \
  jq \
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home gitlab -g root && \
    chown gitlab /usr/local/share/ca-certificates /usr/lib/ssl/certs/ && \
    chmod -R g+rw /usr/local/share/ca-certificates/ /usr/lib/ssl/certs/ && \
    echo "gitlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitlab

COPY --from=builder --chown=gitlab:root /gcs/gcs.gem /gcs/script/setup.sh /gcs/version /home/gitlab/

USER gitlab
ENV HOME "/home/gitlab"
WORKDIR /home/gitlab
RUN ["/bin/bash","./setup.sh"]
RUN gem install /home/gitlab/gcs.gem

CMD ["gtcs", "scan"]
