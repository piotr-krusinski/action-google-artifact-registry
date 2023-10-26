## Description
Build and add docker image to Google Artifact Registry

## Requirements
1. [Create Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/repositories/create-repos)
2. [Grant access to created Artifact Registry](https://cloud.google.com/artifact-registry/docs/access-control#grant)
3. [Create service account key](https://developers.google.com/workspace/guides/create-credentials#:~:text=your%20service%20account%3A-,In%20the%20Google%20Cloud%20console%2C%20go%20to%20Menu%20menu,IAM%20%26%20Admin%20%3E%20Service%20Accounts.&text=Select%20your%20service%20account.,Add%20key%20%3E%20Create%20new%20key.)

## Action parameters
Name                              | Required  | Default value | Description
:---------------------------------|:---------:|:-------------:|:-----------
google_project_id                 | Y         |               | Google project ID of your project where Artifact Registry is created
google_artifact_registry_region   | Y         |               | Google Artifact Registry region
google_artifact_registry_hostname | Y         |               | Google Artifact Registry hostname
google_artifact_registry_name     | Y         |               | Google Artifact Registry repository name
service_account_key               | Y         |               | Base64 version of Google Cloud Platform service key to access Artifact Registry
dockerfile                        | Y         |               | Path to dockerfile
image_name                        | Y         |               | Name of created image
*tag_list*                        | *N*       | *latest*      | Tag list separated by space, if no tag is specified then it will use latest tag (example: `tag_1 tag_2 tag_3`)
*build_args*                      | *N*       |               | List of build args that will be used to build docker image described at [Docker documentation](https://docs.docker.com/build/guide/build-args/)

## Example usage
```
- name: Google Artifact Registry Build & Push
  uses: piotrkrusinski/action-google-artifact-registry@[version tag]
  with:
    google_project_id: [artifact_registry_project_id]
    google_artifact_registry_region: [artifact_registry_region]
    google_artifact_registry_hostname: [artifact_registry_hostname]
    google_artifact_registry_name: [artifact_registry_name]
    service_account_key: [base64 of service key]
    dockerfile: [path to your dockerfile]
    image_name: [image name]
    tag_list: version_1.0 master 20231024_123456
    build_args: docker build args
```