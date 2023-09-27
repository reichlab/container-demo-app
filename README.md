# Introduction

This project demonstrates containerizing a model (the "app") so that it can run on both [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (Amazon ECS) on a schedule, and in local development. In this case the app just updates the [sandbox repo](https://github.com/reichlabmachine/sandbox), posting Slack #tmp messages along the way, but the steps and components involved extend to any kind of non-service app (i.e., one that starts, does its work, and then exits).

# Volume structure

In both local and ECS cases, the app expects the following directories:

- `/data` (directory): Data mount point for the app. Must be support read/write permissions by the executing user.
- `/data/sandbox` (directory): Where the app will clone the [sandbox repo](https://github.com/reichlabmachine/sandbox) if not present.
- `/data/config` (directory): Contains files required to configure the user:
    - `.env` (file): Environment variable file that contains these variables: `SLACK_API_TOKEN` (API token for the lab's slack API), `CHANNEL_ID` (the Slack channel to send messages to), and `GH_TOKEN` (GitHub personal access token that the [GitHub CLI](https://cli.github.com/) will use).
    - `.git-credentials` (file): Cached GitHub personal access token as used by [git-credential-store](https://git-scm.com/docs/git-credential-store).
    - `.gitconfig` (file): [Configuration variables file](https://git-scm.com/docs/git-config#_configuration_file) that must contain the [credential] and [user] sections as follows:

```
[credential]
    helper = store
[user]
    name = <user name>
    email = <user email>
```

# Overall procedure for local development

1. Create a local volume - see "Steps to create a local volume".
1. Build the app image - see "Steps to build the image".
1. Run the image, mounting the new volume - see "Steps to run the image locally".
1. Publish the image - see "Steps to publish the image".

# Steps to create a local volume

Before running the image you must create a [Docker volume](https://docs.docker.com/storage/volumes/) containing a `/data` directory populated as described in "Volume structure" above. Then you can run the image.

Create the following _non-versioned_ files in this repo's `config/` dir (see "Volume structure" above for file details):

- `.env`
- `.gitconfig`
- `.git-credentials`

Run the following commands, which create the volume, mount it in a temporary container, copy the `config/` dir to the volume and then clean up.

Note: the `COPYFILE_DISABLE` variable is necessary only in Mac development to disable AppleDouble format ("._*" files) per [this post](https://superuser.com/questions/61185/why-do-i-get-files-like-foo-in-my-tarball-on-os-x). Otherwise, you'll get files in the volume's `config/` dir like `._.env` and `._.git-credentials`.

```bash
# create the empty volume
docker volume create data_volume

# create a temp container that mounts the volume at `/data`
docker create --name temp_container --mount type=volume,src=data_volume,target=/data ubuntu

# copy the `config/` directory to the volume and then delete the temp container. substitute your repo's root directory for the placeholder shown
COPYFILE_DISABLE=1 tar -c -C /path/to/docker-slack-app config/ | docker cp - temp_container:/data
docker rm temp_container

# verify the volume's contents by printing all files under `/data`. the output should look like this:
# /data
# /data/config
# /data/config/.env
# /data/config/.git-credentials
# /data/config/.gitconfig
docker run --rm -i -v=data_volume:/data ubuntu find /data

# (optional) explore the volume from the command line via a temp container
docker run --rm -it --name temp_container --mount type=volume,src=data_volume,target=/data ubuntu /bin/bash
```

# Steps to build the image

To build the image, run the following command in this repo's root directory, naming it as desired:

```bash
docker build -t slack-app:1.0 .
```

# Steps to run the image locally

Run the following command to run an instance of the app image on a temporary container that has the volume mounted at `/data/`. (Make sure you did the steps in "Steps to build the image" before doing the following.) Remove the `--rm` flag if you want to work with the temp container after it finishes. With luck, you'll see output on the Slack channel configured above by the `config/.env` file. Note that this command demonstrates passing the `SECRET` environment variable to the container, which prints that value.

```bash
# run the image
docker run --rm --mount type=volume,src=data_volume,target=/data -e SECRET='shh!' slack-app:1.0
```

# Steps to publish the image

To publish the image to [Docker Hub](https://hub.docker.com/), run the following command in this repo's root directory, naming it as desired.

```bash
docker tag slack-app:1.0 mattcornell/slack-app:1.0
docker push mattcornell/slack-app:1.0
```

# ECS setup

Set up [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (Amazon ECS) using the following steps. NB: This is complicated to get correct.

## TBD: Steps:

- create an EFS file system
- populate the file system
- create a security group
- create a cluster
- create the task definition
- run a task
- check output
- clean up
