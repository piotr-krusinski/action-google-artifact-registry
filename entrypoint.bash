#!/bin/bash
set -e

# lets decode SA key and save it locally in key file
echo -e "Preparing key used for authentication"
echo "$INPUT_SERVICE_ACCOUNT_KEY" | base64 -d > "$HOME"/sa_key.json

# if no tag is specified use latest, else add latest to the tags anyway
echo -e "Preparing tag list"
if [ -z "$INPUT_TAG_LIST" ]; then
  TAG_LIST=(latest)
else
  TAG_LIST=($INPUT_TAG_LIST latest)
fi
echo -e "  TAG_LIST: ${TAG_LIST}"

#  add build args to the command 
echo -e "Preparing build args"
if [ "$INPUT_BUILD_ARGS" ]; then
  BUILD_ARGS_SPLIT=$(echo "$INPUT_BUILD_ARGS" | tr ',' '\n')
  BUILD_ARGS="--build-arg $(echo $BUILD_ARGS_SPLIT | xargs | sed 's/ / --build-arg /g')"
fi
echo -e "  BUILD_ARGS: ${BUILD_ARGS}"

# authenticate to google using key file
echo -e "Authenticating to gcloud"
gcloud auth activate-service-account --key-file="$HOME"/sa_key.json --project "$INPUT_GOOGLE_PROJECT_ID"

# configure docker with specific Artifact Registry
echo -e "Gcloud Docker configuration"
gcloud auth configure-docker $INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME

echo -e "Preparing tags"
# check tags and create a docker command parameter
BUILD_TAGS=""
for TAG in ${TAG_LIST[@]}; do
  echo -e "  found tag: ${TAG}"
  BUILD_TAGS=" ${BUILD_TAGS} -t $INPUT_IMAGE_NAME:$TAG"
done
echo -e "  BUILD_TAGS: ${BUILD_TAGS}"

echo -e "Building docker image"
# build docker image
docker build -f "$INPUT_DOCKERFILE" $BUILD_TAGS $BUILD_ARGS .

echo -e "Tagging images"
# tag docker images
for TAG in ${TAG_LIST[@]}; do
  IMAGE_TAG=$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
  echo -e "  tag: ${IMAGE_TAG}"
  docker tag ${TAG} ${IMAGE_TAG}
done

echo -e "Pushing images to docker registry"
# push created docker image with specified tags
for TAG in ${TAG_LIST[@]}; do
  IMAGE_TAG=$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
  echo -e "  pushing: ${IMAGE_TAG}"
  docker push $INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
done
