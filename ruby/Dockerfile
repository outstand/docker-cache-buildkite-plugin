FROM ruby:2.7.2-alpine3.12
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

RUN apk add --no-cache ca-certificates wget openssl jq git bash tini su-exec

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV BUNDLER_VERSION 2.1.4
RUN gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force

ENV AWS_VAULT_VERSION 6.2.0
RUN mkdir -p /tmp/vault && \
      cd /tmp/vault && \
      wget https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/aws-vault-linux-amd64 && \
      wget https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/SHA256SUMS && \
      grep aws-vault-linux-amd64 SHA256SUMS | sha256sum -c && \
      chmod +x aws-vault-linux-amd64 && \
      mv aws-vault-linux-amd64 /usr/bin/aws-vault

ENV AWS_VAULT_BACKEND=file

RUN addgroup -g 1000 -S ci && \
    adduser -u 1000 -S -G ci ci

WORKDIR /srv
RUN chown -R ci:ci /srv
COPY --chown=ci:ci Gemfile Gemfile.lock /srv/

USER ci
RUN bundle install

COPY --chown=ci:ci . /srv/

# COPY docker/docker-entrypoint.sh /docker-entrypoint.sh

# ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
# CMD ["rails", "server", "-b", "0.0.0.0"]
