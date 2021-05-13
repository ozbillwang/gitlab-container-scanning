ARG SCANNER=trivy

FROM ruby:2.7.2-slim as builder
RUN rm -rf /var/lib/apt/lists/*
COPY . gcs
WORKDIR /gcs
ENV PATH="/gcs/:${PATH}"
SHELL ["/bin/bash", "-c"]
RUN gem build gcs.gemspec -o gcs.gem

FROM ruby:2.7.2-slim
ARG SCANNER
ENV SCANNER=${SCANNER}
ENV PATH="/home/gitlab:${PATH}"

RUN apt-get update && apt-get install -y -q \
  wget \
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