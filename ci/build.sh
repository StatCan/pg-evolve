#!/bin/sh
function build() {
  registry_login

  echo "Building Dockerfile"
  docker build \
    --build-arg HTTP_PROXY="$HTTP_PROXY" \
    --build-arg http_proxy="$http_proxy" \
    --build-arg HTTPS_PROXY="$HTTPS_PROXY" \
    --build-arg https_proxy="$https_proxy" \
    --build-arg FTP_PROXY="$FTP_PROXY" \
    --build-arg ftp_proxy="$ftp_proxy" \
    --build-arg NO_PROXY="$NO_PROXY" \
    --build-arg no_proxy="$no_proxy" \
    --tag "$CI_APPLICATION_REPOSITORY:$DOCKER_TAG" \
    --tag "$CI_APPLICATION_REPOSITORY:latest" \
    .

  echo "Pushing to Container Registry..."
  docker push "$CI_APPLICATION_REPOSITORY:$DOCKER_TAG"
  docker push "$CI_APPLICATION_REPOSITORY:latest"
  echo ""
}
