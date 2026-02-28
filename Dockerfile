FROM docker.io/library/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk2.0-0 \
    libnss3 \
    sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/sudoers.d \
 && echo "%users ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-users-nopasswd \
 && chmod 0440 /etc/sudoers.d/99-users-nopasswd

CMD ["/bin/bash"]
