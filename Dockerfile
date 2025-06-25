FROM ubuntu:24.04

ENV RUNNER_VERSION="2.325.0" \
    DEBIAN_FRONTEND=noninteractive \
    RUNNER_SHA="5020da7139d85c776059f351e0de8fdec753affc9c558e892472d43ebeb518f4"

# Update and upgrade the system
RUN apt update -y && apt upgrade -y

# Add a user named docker
RUN useradd -m docker

# Install necessary packages
RUN apt install -y --no-install-recommends \
    curl build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip jq ssh

# Set up the actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    echo "$RUNNER_SHA actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm -f actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Change ownership to docker user and install dependencies
RUN chown -R docker /home/docker && /home/docker/actions-runner/bin/installdependencies.sh

# Copy the start script and make it executable
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch to docker user
USER docker

# Define the entrypoint
ENTRYPOINT ["/start.sh"]
