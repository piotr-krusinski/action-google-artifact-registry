#!/bin/bash
set -e

# lets decode SA key and save it locally in key file
echo "$INPUT_SERVICE_ACCOUNT_KEY" | base64 -d > "$HOME"/sa_key.json

# if no tag is specified use latest, else add latest to the tags anyway
if [ -z "$INPUT_TAG_LIST" ]; then
  TAG_LIST=(latest)
else
  TAG_LIST=($INPUT_TAG_LIST latest)
fi

#  add build args to the command 
if [ "$INPUT_BUILD_ARGS" ]; then
  BUILD_ARGS_SPLIT=$(echo "$INPUT_BUILD_ARGS" | tr ',' '\n')
  BUILD_ARGS="--build-arg $(echo $BUILD_ARGS_SPLIT | xargs | sed 's/ / --build-arg /g')"
fi

# authenticate to google using key file
gcloud auth activate-service-account --key-file="$HOME"/sa_key.json --project "$INPUT_GOOGLE_PROJECT_ID"

# configure docker with specific Artifact Registry
gcloud auth configure-docker $INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME

# check tags and create a docker command parameter
BUILD_TAGS=""
for TAG in ${TAG_LIST[@]}; do
  BUILD_TAGS=" ${BUILD_TAGS} -t $INPUT_IMAGE_NAME:$TAG"
done

# build docker image
docker build -f "$INPUT_DOCKERFILE" $BUILD_TAGS $BUILD_ARGS .

# push created docker image with specified tags
for TAG in ${TAG_LIST[@]}; do
  docker push $TAG
fi


