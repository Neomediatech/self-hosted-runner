FROM ghcr.io/neomediatech/ubuntu-base:24.04

ENV RUNNER_VERSION="2.327.0" \
    DEBIAN_FRONTEND=noninteractive

# Add a user named docker
RUN groupadd -g 2375 docker && \
    useradd -m -g 2375 docker

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates libicu-dev ssh \
      skopeo jq git gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm -f actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

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
    rm -rf /var/lib/apt/lists/*

# Change ownership to docker user and install dependencies
RUN chown -R docker /home/docker && /home/docker/actions-runner/bin/installdependencies.sh

# Copy the start script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch to docker user
USER docker

# Define the entrypoint
ENTRYPOINT ["/start.sh"]
