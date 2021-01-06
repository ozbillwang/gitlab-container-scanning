FROM ruby:2.7.2-slim as builder
ENV TRIVY_VERSION=0.13.0
ENV TRIVY_CACHE_DIR='/gcs/.cache'
RUN apt-get update && apt-get install -y -q \
  wget \
  && rm -rf /var/lib/apt/lists/*
COPY . gcs
WORKDIR /gcs
ENV PATH="/gcs/:${PATH}"
RUN ["/bin/bash","./script/build.sh"]

FROM ruby:2.7.2-slim
ENV TRIVY_CACHE_DIR='/opt/gitlab/.cache'
ENV PATH="/opt/gitlab:${PATH}"
COPY --from=builder /gcs/trivy /gcs/gcs.gem /opt/gitlab/
COPY --from=builder /gcs/trivy.db /gcs/metadata.json /opt/gitlab/.cache/db/
RUN apt-get update && apt-get install -y -q \
  ca-certificates \
  git-core \
  && rm -rf /var/lib/apt/lists/*
RUN gem install opt/gitlab/gcs.gem
WORKDIR /