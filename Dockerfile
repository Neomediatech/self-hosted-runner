FROM ghcr.io/neomediatech/ubuntu-base:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Rome

ARG APP_VERSION=latest

# Add a user named docker
RUN groupadd -g 2375 docker && \
    useradd -m -g 2375 docker

RUN echo $TZ > /etc/timezone

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends libicu-dev ssh \
      skopeo jq git gh tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the actions runner
RUN APP_URL="https://api.github.com/repos/actions/runner/releases" && \
    if [ "$APP_VERSION" = "latest" ]; then \
	TAG=""; \
    else \
	TAG="tags/"; \
    fi && \
    echo "TAG=$TAG" && \
    echo "APP_VERSION=$APP_VERSION" && \
    REPO_VERSION="$(basename $(curl -s $APP_URL/${TAG}${APP_VERSION} | jq -r '.tag_name'))" && \
    echo "REPO_VERSION=$REPO_VERSION" && \
	FILE_NAME="actions-runner-linux-x64-${REPO_VERSION#v}.tar.gz" && \
	echo "repo download: https://github.com/actions/runner/releases/download/${REPO_VERSION}/$FILE_NAME" && \
    cd /home/docker && mkdir actions-runner && cd actions-runner && \
    curl -o $FILE_NAME -L https://github.com/actions/runner/releases/download/${REPO_VERSION}/$FILE_NAME && \
    tar xzf $FILE_NAME && \
    rm -f $FILE_NAME

# Install Docker
RUN apt-get remove docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc || ok=true
# Add Docker's official GPG key & Add the repository to Apt sources
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get -y install docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chown -R docker /home/docker

# install dependencies
RUN sed -i 's|#!/bin/bash|#!/bin/bash\nset -x|' /home/docker/actions-runner/bin/installdependencies.sh && \
    /home/docker/actions-runner/bin/installdependencies.sh

# Copy the start script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch to docker user
USER docker

# Define the entrypoint
ENTRYPOINT ["/start.sh"]
