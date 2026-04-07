# Build stack image – used during the build phase of the CNB lifecycle.
# Ubuntu 24.04 provides the full toolchain needed to compile Java apps
# with the Paketo Java and Java Native Image buildpacks.

FROM ubuntu:24.04@sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b

ARG CNB_USER_ID=1000
ARG CNB_GROUP_ID=1000

LABEL io.buildpacks.stack.id="io.buildpacks.stacks.noble"
LABEL io.buildpacks.base.distro.name="ubuntu"
LABEL io.buildpacks.base.distro.version="24.04"
LABEL maintainer="patbaumgartner"
LABEL org.opencontainers.image.source="https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny"
LABEL org.opencontainers.image.description="Build stack image for the Distroless Buildpack Builder Java Tiny (Ubuntu 24.04 Noble)"

# Install build-time dependencies for Java (JVM and Native Image).
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fontconfig \
    git \
    libssl-dev \
    netbase \
    openssl \
    tzdata \
    unzip \
    xz-utils \
    zip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Create the CNB user/group (remove default 'ubuntu' user if present).
RUN if getent passwd ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi \
    && if getent group ubuntu >/dev/null 2>&1; then groupdel ubuntu; fi \
    && groupadd --gid "${CNB_GROUP_ID}" cnb \
    && useradd \
    --uid  "${CNB_USER_ID}" \
    --gid  cnb \
    --shell /bin/bash \
    --create-home \
    cnb

# Create CNB working directories.
RUN mkdir -p /workspace /cnb/buildpacks /platform /layers \
    && chown -R cnb:cnb /workspace /cnb /platform /layers

USER cnb

# The CNB lifecycle reads these env vars at runtime to know which user to run buildpacks as.
ENV CNB_STACK_ID="io.buildpacks.stacks.noble"
ENV CNB_USER_ID=1000
ENV CNB_GROUP_ID=1000
