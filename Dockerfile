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
  sudo \
  && rm -rf /var/lib/apt/lists/* \
  &&  useradd --create-home gitlab -g root

COPY --from=ghcr.io/oras-project/oras:v0.12.0 /bin/oras /usr/local/bin/

COPY --from=builder --chown=gitlab:root /gcs/gcs.gem /gcs/script/setup.sh /gcs/version /home/gitlab/

RUN chown gitlab /usr/local/share/ca-certificates /usr/lib/ssl/certs/ && \
    chmod -R g+rw /usr/local/share/ca-certificates/ /usr/lib/ssl/certs/ && \
    echo "gitlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitlab && \
    gem install --no-document /home/gitlab/gcs.gem && \
    su - gitlab -c "export SCANNER=$SCANNER PATH="/home/gitlab:${PATH}"; cd /home/gitlab && bash setup.sh" && \
    apt-get remove -y curl wget xauth && \
    apt-get autoremove -y && \
    rm -f /usr/local/bin/oras

USER gitlab
ENV HOME "/home/gitlab"

WORKDIR /home/gitlab
CMD ["gtcs", "scan"]
