#!/bin/bash
#
# 1. go to https://github.com/settings/tokens
# 2. generate new token (fine-grained) with "Self-hosted runners" permissions
# 3. put the token in GITHUB_PAT variable in your .env file or in the docker-compose.yml file
#
REPO=$REPO
#REG_TOKEN=$REG_TOKEN
NAME=$(hostname)
GITHUB_PAT=$GITHUB_PAT

cd /home/docker/actions-runner || exit

REG_TOKEN=$(curl -sX POST -H "Authorization: token $GITHUB_PAT" "https://api.github.com/orgs/$REPO/actions/runners/registration-token" | jq -r .token)
    
./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN} --name ${NAME}
./config.sh --url "$RUNNER_URL" --token "$REG_TOKEN" --unattended --name "$(hostname)-runner" --replace

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
