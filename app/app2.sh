#!/bin/bash

#
# This is a small script to drive creating a Docker image that we can run as a batch job from AWS ECS and EFS.
#

# load slack functions. NB: requires two environment variables: SLACK_API_TOKEN and CHANNEL_ID .
# done first b/c we start in WORKDIR, which we lose through later `cd`s

SLACK_FILE="./slack.sh"
if [ ! -f "${SLACK_FILE}" ]; then
  echo "required file not found: '${SLACK_FILE}'"
  exit 1 # failure
else
  echo "required file found: '${SLACK_FILE}'. loading"
  source "${SLACK_FILE}"
fi

# check for required dirs (we don't check '/data' parent b/c it's present if subdir found)
CONFIG_DIR="/data/config"
if [ ! -d "${CONFIG_DIR}" ]; then
  echo "required dir not found: '${CONFIG_DIR}'"
  exit 1 # failure
else
  echo "required dir found: '${CONFIG_DIR}'"
fi

# check for required files, copying to home dir if found (recall that home dir is ephemeral)
REQUIRED_FILES="/data/config/.env /data/config/.gitconfig /data/config/.git-credentials"
for FILE in ${REQUIRED_FILES}; do
  if [ ! -f "${FILE}" ]; then
    echo "required file not found: '${FILE}'"
    exit 1 # failure
  else
    echo "required file found: '${FILE}'. copying to '${HOME}'"
    cp "${FILE}" "${HOME}"
  fi
done

# load environment variables - per https://stackoverflow.com/questions/19331497/set-environment-variables-from-file-of-key-value-pairs
set -o allexport
source ~/.env
set +o allexport

# clone the sandbox app if necessary
SANDBOX_DIR="/data/sandbox/"
if [ ! -d "${SANDBOX_DIR}" ]; then
  cd /data
  git clone https://github.com/reichlabmachine/sandbox.git
fi

# run the "app"
slack_message "started. editing file"
cd /data/sandbox/
git pull
echo "$(date)" >>README.md
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
