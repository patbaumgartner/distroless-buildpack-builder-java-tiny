# Run stack image – used as the runtime base for built application images.
#
# Stage 1 (ubuntu-setup): CNB user/group + tzdata.
# Stage 2 (final):        Google Distroless base with injected user.
#
# Java (JVM) runtime needs: the JVM bundles its own TLS stack (JSSE) and does
# not rely on system OpenSSL.  The distroless/cc base already ships libstdc++
# and libgcc which is all a JVM needs from the OS.  Timezone data is the only
# extra required for JVM-based apps such as Spring Boot.
# /etc/services and /etc/protocols (netbase) are not used by the JVM or Spring
# Boot and are intentionally omitted to keep the image minimal.

# Stage 1: Ubuntu setup (user/group)
FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c AS ubuntu-setup

ARG CNB_USER_ID=1002
ARG CNB_GROUP_ID=1000

# Remove default 'ubuntu' user if present so we can claim GID 1000 for CNB.
RUN if getent passwd ubuntu >/dev/null 2>&1; then userdel --remove ubuntu; fi \
    && if getent group ubuntu >/dev/null 2>&1; then groupdel ubuntu; fi \
    && groupadd --gid "${CNB_GROUP_ID}" cnb \
    && useradd \
    --uid  "${CNB_USER_ID}" \
    --gid  cnb \
    --no-create-home \
    cnb

# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata \
    && rm -rf /var/lib/apt/lists/*


FROM gcr.io/distroless/cc:nonroot@sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e

ARG CNB_USER_ID=1002
ARG CNB_GROUP_ID=1000

COPY --from=ubuntu-setup /etc/passwd /etc/passwd
COPY --from=ubuntu-setup /etc/group  /etc/group

# Timezone data
COPY --from=ubuntu-setup /usr/share/zoneinfo /usr/share/zoneinfo

LABEL io.buildpacks.stack.id="io.buildpacks.stacks.noble"
LABEL io.buildpacks.base.distro.name="distroless"
LABEL io.buildpacks.base.distro.version="cc"
LABEL maintainer="patbaumgartner"
LABEL org.opencontainers.image.source="https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny"
LABEL org.opencontainers.image.description="Run stack image for the Distroless Buildpack Builder Java Tiny (Google Distroless cc)"

USER ${CNB_USER_ID}:${CNB_GROUP_ID}
