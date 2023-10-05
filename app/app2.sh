#!/bin/bash

#
# This is a small script to drive creating a Docker image that we can run as a batch job from AWS ECS and EFS.
#

# write incoming environment variables into three files. required variables:

# verify all vars passed in
if [ -z ${SLACK_API_TOKEN+x} ] || [ -z ${CHANNEL_ID+x} ] || [ -z ${GH_TOKEN+x} ] || [ -z ${GIT_USER_NAME+x} ] || [ -z ${GIT_USER_EMAIL+x} ] || [ -z ${GIT_CREDENTIALS+x} ]; then
  echo "one or more required environment variables were unset: SLACK_API_TOKEN='${SLACK_API_TOKEN}', CHANNEL_ID='${CHANNEL_ID}', GH_TOKEN='${GH_TOKEN}', GIT_USER_NAME='${GIT_USER_NAME}', GIT_USER_EMAIL='${GIT_USER_EMAIL}', GIT_CREDENTIALS='${GIT_CREDENTIALS}'"
  exit 1 # failure
else
  echo "found all required environment variables"
fi

# file 1/3: ~/.env
ENV_FILE_NAME="${HOME}/.env"
echo "SLACK_API_TOKEN=${SLACK_API_TOKEN}" >"${ENV_FILE_NAME}" # NB: overwrites!
echo "CHANNEL_ID=${CHANNEL_ID}" >>"${ENV_FILE_NAME}"
echo "GH_TOKEN=${GH_TOKEN}" >>"${ENV_FILE_NAME}"

# file 2/3: ~/.git-credentials
echo "${GIT_CREDENTIALS}" >"${HOME}/.git-credentials"

# file 3/3: ~/.gitconfig
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git config --global credential.helper store

# load environment variables - per https://stackoverflow.com/questions/19331497/set-environment-variables-from-file-of-key-value-pairs
set -o allexport
source "${ENV_FILE_NAME}"
set +o allexport

# load slack functions. NB: requires SLACK_API_TOKEN and CHANNEL_ID environment variables
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
gh issue list
if [ $? -eq 0 ]; then
  slack_message "gh OK"
else
  slack_message "gh FAILED"
fi

slack_upload README.md
slack_message "done"
