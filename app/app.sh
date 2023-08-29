#!/bin/bash

#
# This is a simple script to drive creating a Docker image that we can run as a batch job from AWS.
#

# load slack functions - per https://stackoverflow.com/questions/10822790/can-i-call-a-function-of-a-shell-script-from-another-shell-script/42101141#42101141
# NB: requires two environment variables: SLACK_API_TOKEN and CHANNEL_ID
source ./slack.sh

# run the "app"
slack_message "test Docker app ran"
