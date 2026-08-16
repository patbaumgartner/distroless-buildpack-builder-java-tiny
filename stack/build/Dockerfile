# Build stack image – used during the build phase of the CNB lifecycle.
# Ubuntu 24.04 provides the full toolchain needed to compile Java apps
# with the Paketo Java and Java Native Image buildpacks.
#
# The Ubuntu major version is a HARD COMPATIBILITY CONSTRAINT, not a
# free-floating dependency. GraalVM links Native Image binaries against this
# image's glibc, but they execute in the run image (Google Distroless, Debian
# 13, glibc 2.41). Building on a newer glibc than the runtime provides emits
# symbol references the runtime cannot resolve, and the binary dies at startup
# with "version `GLIBC_2.xx' not found".
#
#   ubuntu:24.04 -> glibc 2.39  <= 2.41  OK
#   ubuntu:26.04 -> glibc 2.43   > 2.41  BREAKS Native Image at runtime
#
# Do not raise this past the run image's glibc. See .github/dependabot.yml,
# which restricts this image to patch/digest updates for the same reason.

FROM ubuntu:24.04@sha256:561618e2c15bf2397621dd04f96926663a3b5616c189cf7e38db7e82f5c538ea

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
# Keep them bound to the ARGs: a literal would drift from a --build-arg override.
ENV CNB_STACK_ID="io.buildpacks.stacks.noble"
ENV CNB_USER_ID=${CNB_USER_ID}
ENV CNB_GROUP_ID=${CNB_GROUP_ID}
