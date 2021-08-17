ARG SCANNER=trivy

FROM ruby:3.0-slim AS base

FROM base AS builder
ENV PATH="/gcs/:${PATH}"
RUN apt-get update && apt-get install -y -q build-essential
RUN rm -rf /var/lib/apt/lists/*

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
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home gitlab -g root && \
    chown gitlab /usr/local/share/ca-certificates /usr/lib/ssl/certs/ && \
    chmod -R g+rw /usr/local/share/ca-certificates/ /usr/lib/ssl/certs/ && \
    echo "gitlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitlab

COPY --from=builder --chown=gitlab:root /gcs/gcs.gem /gcs/script/setup.sh /gcs/version /home/gitlab/

USER gitlab
ENV HOME "/home/gitlab"

RUN gem install /home/gitlab/gcs.gem
WORKDIR /home/gitlab
RUN ["/bin/bash","./setup.sh"]
CMD ["gtcs", "scan"]
