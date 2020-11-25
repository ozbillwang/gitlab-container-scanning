FROM ruby:2.7.2-slim as builder
ENV TRIVY_VERSION=0.13.0
RUN apt-get update && apt-get install -y -q \
  wget \
  git \
  && rm -rf /var/lib/apt/lists/*
COPY . gcs
# RUN bash gcs/script/build