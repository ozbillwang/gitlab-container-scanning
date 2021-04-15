FROM ruby:2.7.2-slim as builder
ENV TRIVY_VERSION=0.16.0
ENV TRIVY_CACHE_DIR='/gcs/.cache'
RUN apt-get update && apt-get install -y -q \
  wget \
  && rm -rf /var/lib/apt/lists/*
COPY . gcs
WORKDIR /gcs
ENV PATH="/gcs/:${PATH}"
RUN ["/bin/bash","./script/build.sh"]

FROM ruby:2.7.2-slim
ENV TRIVY_CACHE_DIR='/home/gitlab/.cache'
ENV PATH="/home/gitlab:${PATH}"

RUN apt-get update && apt-get install -y -q \
  ca-certificates \
  git-core \
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home gitlab -g root && \
    chown gitlab /usr/local/share/ca-certificates /usr/lib/ssl/certs/ && \
    chmod -R g+rw /usr/local/share/ca-certificates/ /usr/lib/ssl/certs/ && \
    echo "gitlab ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitlab

COPY --from=builder --chown=gitlab:root /gcs/trivy /gcs/gcs.gem /home/gitlab/
COPY --from=builder --chown=gitlab:root /gcs/trivy.db /gcs/metadata.json /home/gitlab/.cache/db/

RUN chmod -R g+rw /home/gitlab/.cache/

USER gitlab
ENV HOME "/home/gitlab"

RUN gem install /home/gitlab/gcs.gem
WORKDIR /home/gitlab
CMD ["gtcs", "scan"]

