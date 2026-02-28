FROM docker.io/library/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk2.0-0 \
    libnss3 \
    sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Allow passwordless sudo for any user in the sudo group
RUN echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ARG USERNAME=gloo
RUN groupadd -f sudo && usermod -aG sudo $USERNAME 2>/dev/null || true

CMD ["/bin/bash"]
