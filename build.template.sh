#!/usr/bin/env bash

function exit_with_error {
	echo "$1" 1>&2
	exit 1
}

function print_header {
  printf "\n\n
    ===========================================================
    $1
    ===========================================================
    \n\n";
}

if [ -z "${COMPONENT_NAME}" ];
then exit_with_error "Component name (COMPONENT_NAME) must be specified."
fi


ENVIRONMENT=${ENVIRONMENT:-production}
VERSION=${VERSION:-latest}

BUILD_NAME=${ENVIRONMENT}-${VERSION}
BUILDER_IMAGE_NAME=${COMPONENT_NAME}-builder:${BUILD_NAME}
APP_IMAGE_NAME=just-married/${COMPONENT_NAME}:${BUILD_NAME}

BUILD_ENVIRONMENT=${BUILD_ENVIRONMENT:-}

mkdir -p artifacts

print_header "STARTING BUILD (IMAGE ${APP_IMAGE_NAME})"

print_header "BUILD STEP 1 (Building container for building ${BUILD_NAME})"

docker build \
  -f containers/build/Dockerfile \
  --build-arg ENVIRONMENT=${ENVIRONMENT} \
  --build-arg VERSION=${VERSION} \
  -t ${BUILDER_IMAGE_NAME} . \
  || exit_with_error "Could not build container for building ${BUILD_NAME}"



print_header "BUILD STEP 2 (Running build container ${BUILDER_IMAGE_NAME})"

ARTIFACT=$(docker run \
  -v $(pwd)/artifacts:/artifacts \
  ${BUILD_ENVIRONMENT} \
  ${BUILDER_IMAGE_NAME} \
  || exit_with_error "Could not run build container ${BUILDER_IMAGE_NAME}") | tail -1



print_header "BUILD STEP 3 (Dockerizing artifact ${ARTIFACT} built by ${BUILDER_IMAGE_NAME} into application image ${APP_IMAGE_NAME})"

docker build \
  -f containers/deploy/Dockerfile \
  -t ${APP_IMAGE_NAME} . \
  --build-arg ARTIFACT=${ARTIFACT} \
  || exit_with_error "Could not dockerize application built by ${BUILDER_IMAGE_NAME} into ${APP_IMAGE_NAME}"


print_header "BUILD COMPLETE (IMAGE ${APP_IMAGE_NAME})"
