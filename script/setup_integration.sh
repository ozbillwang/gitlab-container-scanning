#!/bin/sh

set -e

cd "$(dirname "$0")/.."

if command -v apk; then
  apk add \
    bash \
    build-base \
    curl \
    git \
    ruby \
    ruby-rake \
    ruby-bigdecimal \
    ruby-bundler \
    ruby-dev \
    ruby-json
fi

bundle config --local jobs "$(nproc)"
bundle install --no-cache  --quiet
ruby -v