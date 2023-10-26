#!/bin/bash
set -e

echo -e "[ACTION] Checking if required parameters are set"
if [ -z "$INPUT_GOOGLE_PROJECT_ID" ];                  then echo -e "[ACTION] Requirements not met: GOOGLE_PROJECT_ID not set";                  exit 1; fi
if [ -z "$INPUT_GOOGLE_ARTIFACT_REGISTRY_REGION" ];    then echo -e "[ACTION] Requirements not met: GOOGLE_ARTIFACT_REGISTRY_REGION not set";    exit 1; fi
if [ -z "$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME" ];  then echo -e "[ACTION] Requirements not met: GOOGLE_ARTIFACT_REGISTRY_HOSTNAME not set";  exit 1; fi
if [ -z "$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME" ];      then echo -e "[ACTION] Requirements not met: GOOGLE_ARTIFACT_REGISTRY_NAME not set";      exit 1; fi
if [ -z "$INPUT_SERVICE_ACCOUNT_KEY" ];                then echo -e "[ACTION] Requirements not met: SERVICE_ACCOUNT_KEY not set";                exit 1; fi
if [ -z "$INPUT_DOCKERFILE" ];                         then echo -e "[ACTION] Requirements not met: DOCKERFILE not set";                         exit 1; fi
if [ -z "$INPUT_IMAGE_NAME" ];                         then echo -e "[ACTION] Requirements not met: IMAGE_NAME not set";                         exit 1; fi


# lets decode SA key and save it locally in key file
echo -e "[ACTION] Preparing key used for authentication"
echo "$INPUT_SERVICE_ACCOUNT_KEY" | base64 -d > "$HOME"/sa_key.json

# if no tag is specified use latest, else add latest to the tags anyway
echo -e "[ACTION] Preparing tag list"
if [ -z "$INPUT_TAG_LIST" ]; then
  TAG_LIST=(latest)
else
  TAG_LIST=($INPUT_TAG_LIST latest)
fi
echo -e "[ACTION]   TAG_LIST: ${TAG_LIST}"

#  add build args to the command 
echo -e "[ACTION] Preparing build args"
if [ "$INPUT_BUILD_ARGS" ]; then
  BUILD_ARGS_SPLIT=$(echo "$INPUT_BUILD_ARGS" | tr ',' '\n')
  BUILD_ARGS="--build-arg $(echo $BUILD_ARGS_SPLIT | xargs | sed 's/ / --build-arg /g')"
fi
echo -e "[ACTION]   BUILD_ARGS: ${BUILD_ARGS}"

# authenticate to google using key file
echo -e "[ACTION] Authenticating to gcloud"
gcloud auth activate-service-account --key-file="$HOME"/sa_key.json --project "$INPUT_GOOGLE_PROJECT_ID"

# configure docker with specific Artifact Registry
echo -e "[ACTION] docker configuration"
docker login -u _json_key --password-stdin https://$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME < "$HOME"/sa_key.json

echo -e "[ACTION] Preparing tags"
# check tags and create a docker command parameter
BUILD_TAGS=""
for TAG in ${TAG_LIST[@]}; do
  echo -e "[ACTION]   found tag: ${TAG}"
  BUILD_TAGS=" ${BUILD_TAGS} -t $INPUT_IMAGE_NAME:$TAG"
done
echo -e "[ACTION]   BUILD_TAGS: ${BUILD_TAGS}"

echo -e "[ACTION] Building docker image"
# build docker image
docker build -f "$INPUT_DOCKERFILE" $BUILD_TAGS $BUILD_ARGS .

echo -e "[ACTION] Tagging images"
# tag docker images
for TAG in ${TAG_LIST[@]}; do
  IMAGE_TAG=$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
  echo -e "[ACTION]   tag: $IMAGE_TAG"
  docker tag $INPUT_IMAGE_NAME:$TAG $IMAGE_TAG
done

echo -e "[ACTION] Pushing images to docker registry"
# push created docker image with specified tags
for TAG in ${TAG_LIST[@]}; do
  IMAGE_TAG=$INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
  echo -e "[ACTION]   pushing: $IMAGE_TAG"
  docker push $INPUT_GOOGLE_ARTIFACT_REGISTRY_HOSTNAME/$INPUT_GOOGLE_PROJECT_ID/$INPUT_GOOGLE_ARTIFACT_REGISTRY_NAME/$INPUT_IMAGE_NAME:$TAG
done
