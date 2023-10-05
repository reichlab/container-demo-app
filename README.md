# Introduction

This project demonstrates containerizing a model (the "app") so that it can run on both [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (Amazon ECS) on a schedule, and in local development. In this case the app just updates the [sandbox repo](https://github.com/reichlabmachine/sandbox), posting Slack [#tmp channel](https://app.slack.com/client/T089JRGMA/C02UELXDPQQ) messages along the way, but the steps and components involved extend to any kind of non-service app (i.e., one that starts, does its work, and then exits).

# Volume structure

In both local and ECS cases, the app expects a volume to be mounted at `/data`. It must have read/write permissions by the executing user. This is where any required git repositories are expected to be cloned. It's also where `app2.sh` will clone the [sandbox repo](https://github.com/reichlabmachine/sandbox) if not present.

# Environment variables

`app2.sh` requires the following environment variables.

> Note It's easiest and safest to save these in a `*.env` file and then pass that file to `docker run` as done below in "Steps to run the image locally".

- `SLACK_API_TOKEN`, `CHANNEL_ID`: [API token](https://api.slack.com/authentication/token-types#bot) for the lab's slack API and the Slack channel id to send messages to, respectively. Saved into `~/.env`.
- `GH_TOKEN`: [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) that the [GitHub CLI](https://cli.github.com/) will use. Saved into `~/.env`.
- `GIT_USER_NAME`, `GIT_USER_EMAIL`: Global `user.name` and `user.email` values to save into the `~/.gitconfig` [Configuration variables file](https://git-scm.com/docs/git-config#_configuration_file) via `git config --global ...`.
- `GIT_CREDENTIALS`: GitHub personal access token as used by [git-credential-store](https://git-scm.com/docs/git-credential-store). Saved into `~/.git-credentials`.

# Overall procedure for local development

1. Create a local volume - see "Steps to create a local volume".
1. Build the app image - see "Steps to build the image".
1. Run the image, mounting the new volume - see "Steps to run the image locally".
1. Publish the image - see "Steps to publish the image".

# Steps to create a local volume

Before running the image you must create a [Docker volume](https://docs.docker.com/storage/volumes/) containing a `/data` directory as described in "Volume structure" above. Then you can run the image.

Run the following commands, which create the volume and then list its contents to verify it exists and can be mounted at `/data`.

```bash
cd "<path to this repo>"

# create the empty volume
docker volume create data_volume

# verify the volume's contents by listing `/data` contents
docker run --rm -i -v=data_volume:/data ubuntu ls -al /data

# (optional) explore the volume from the command line via a temp container
docker run --rm -it --name temp_container --mount type=volume,src=data_volume,target=/data ubuntu /bin/bash
```

# Steps to build the image

To build the image, run the following command in this repo's root directory, naming it as desired:

```bash
cd "<path to this repo>"
docker build -t container-demo-app:1.0 .
```

# Steps to run the image locally

Run the following command to run an instance of the app image on a temporary container that has the volume mounted at `/data/`. (Make sure you did the steps in "Steps to build the image" before doing the following.) Remove the `--rm` flag if you want to work with the temp container after it finishes. With luck, you'll see output on the Slack channel set in the `.env` file.

> Note: The command assumes you've created a `config/.env` file that contains the required environment variables documented above in "Environment variables".

```bash
# run the image
cd "<path to this repo>"
docker run --rm \
  --mount type=volume,src=data_volume,target=/data \
  --env-file config/.env \
  container-demo-app:1.0
```

# Steps to publish the image

To publish the image to the [Docker Hub container-demo-app reichlab](https://hub.docker.com/repository/docker/reichlab/container-demo-app/) repository, run the following command in this repo's root directory, tagging it as desired.

```bash
docker login -u "reichlab" docker.io
docker tag container-demo-app:1.0 reichlab/container-demo-app:1.0
docker push reichlab/container-demo-app:1.0
```

# Steps to set up AWS ECS

See [ecs.md](ecs.md) for instructions to set up [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (Amazon ECS) to run your image on their [Fargate Serverless Compute Engine](https://aws.amazon.com/fargate/).
