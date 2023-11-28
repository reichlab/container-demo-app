#!/bin/bash

#
# This is a small script to drive creating a Docker image that we can run as a batch job from AWS ECS and EFS.
#

# load environment variables and then slack functions. see https://github.com/reichlab/container-utils/README.md for
# information about required environment variables. assumes that repo has been cloned at the root of this repo.
source "container-utils/scripts/load-env-vars.sh"
source "container-utils/scripts/slack.sh"

slack_message "entered. id='$(id -u -n)', HOME='${HOME}', PWD='${PWD}'"

# clone the sandbox app if necessary
SANDBOX_DIR="/data/sandbox"
if [ ! -d "${SANDBOX_DIR}" ]; then
  slack_message "cloning sandbox. SANDBOX_DIR='${SANDBOX_DIR}'"
  git clone -C "${SANDBOX_DIR}/.." https://github.com/reichlabmachine/sandbox.git
fi

# print DRY_RUN info
if [ -n "${DRY_RUN+x}" ]; then
  slack_message "DRY_RUN set: '${DRY_RUN}'"
else
  slack_message "DRY_RUN not set"
fi

# run the "app"
slack_message "editing file"
cd "${SANDBOX_DIR}"
ls -al
git pull
date >>"README.md"
git add .
git commit -m "update"

slack_message "pushing"
git push # where any GitHub authentication trouble will be

# test `gh` authentication
slack_message "calling gh"
gh issue list
if [ $? -eq 0 ]; then
  slack_message "gh OK"
else
  slack_message "gh FAILED"
fi

slack_upload README.md
slack_message "done"
