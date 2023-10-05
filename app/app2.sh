#!/bin/bash

#
# This is a small script to drive creating a Docker image that we can run as a batch job from AWS ECS and EFS.
#

# load environment variables and then slack functions. NB: requires SLACK_API_TOKEN and CHANNEL_ID environment variables
source "./load-env-vars.sh"
source "./slack.sh"

slack_message "entered. USER='${USER}', HOME='${HOME}', PWD='${PWD}'"

# clone the sandbox app if necessary
SANDBOX_DIR="/data/sandbox"
if [ ! -d "${SANDBOX_DIR}" ]; then
  git clone -C "${SANDBOX_DIR}/.." https://github.com/reichlabmachine/sandbox.git
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
