# Docker Cache Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/plugins) that lets you cache the contents of docker volumes.

## :warning: Requires an in-development version of the [docker-compose buildkite plugin](https://github.com/outstand/docker-compose-buildkite-plugin/tree/wrap_command) :warning:

## Example

docker-compose.yml:
```yml
version: "3.8"
services:
  rails:
    build: .
    volumes:
      - bundler-data:/usr/local/bundle

volumes:
  bundler-data:
```

pipeline.yml:
```yml
steps:
  - command: bundle install
    plugins:
      - docker-cache#v1.0.0:
          s3_bucket: my-cache-bucket
          keys:
            - v1-bundler-cache-{{ arch }}-{{ checksum "Gemfile.lock" }}
            - v1-bundler-cache-{{ arch }}
          save: true
          volumes:
            - bundler-data

      - docker-compose#v3.7.0:
          run: app

  - command: rspec spec
    plugins:
      - docker-cache#v1.0.0:
          s3_bucket: my-cache-bucket
          keys:
            - v1-bundler-cache-{{ arch }}-{{ checksum "Gemfile.lock" }}
            - v1-bundler-cache-{{ arch }}
          volumes:
            - bundler-data

      - docker-compose#v3.7.0:
          run: app
```
