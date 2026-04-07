# Run stack image – minimal runtime base for CNB-built Java application images.
#
# Three-stage build: an Ubuntu helper (stage 1) creates the CNB user and extracts UTC
# timezone data; a second Ubuntu layer (stage 2) copies distroless/cc into /rootfs and
# strips ~4–5 MB of libraries Java never uses (OpenSSL, CA bundle, libgomp, libitm,
# libatomic, full zoneinfo); the final image (stage 3) is assembled FROM scratch.
# Architecture-agnostic: usr/lib/*/ globs cover both amd64 and arm64.

# Stage 1: Ubuntu setup — CNB user/group and tzdata extraction
FROM ubuntu:24.04@sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b AS ubuntu-setup

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

# Install tzdata only to extract the UTC zone file.  The JVM uses its own
# bundled TZDB so the full zoneinfo tree is not needed at runtime.
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Trim distroless/cc
# The distroless/cc image bundles OpenSSL (libssl3 + libcrypto, ~4 MB), a full CA
# certificate bundle, and several GCC-era shared libraries that a JVM-only workload
# never dlopen.  Because distroless has no shell we cannot run rm inside it directly;
# instead we copy its entire filesystem into /rootfs inside an Ubuntu helper layer,
# delete the dead-weight files, and hand /rootfs to the scratch stage below.
FROM gcr.io/distroless/cc:nonroot@sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e AS distroless-src
# hadolint ignore=DL3006
FROM ubuntu:24.04@sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b AS cc-trimmer
COPY --from=distroless-src / /rootfs/
# hadolint ignore=SC2114
RUN rm -rf \
    /rootfs/usr/lib/*/libssl.so.3     \
    /rootfs/usr/lib/*/libssl.so.3.*   \
    /rootfs/usr/lib/*/libcrypto.so.3  \
    /rootfs/usr/lib/*/libcrypto.so.3.* \
    /rootfs/usr/lib/*/engines-3       \
    /rootfs/usr/lib/*/ossl-modules    \
    /rootfs/etc/ssl                   \
    /rootfs/etc/ca-certificates.conf  \
    /rootfs/usr/share/ca-certificates \
    /rootfs/usr/lib/*/libgomp.so.1    \
    /rootfs/usr/lib/*/libgomp.so.1.*  \
    /rootfs/usr/lib/*/libitm.so.1     \
    /rootfs/usr/lib/*/libitm.so.1.*   \
    /rootfs/usr/lib/*/libatomic.so.1  \
    /rootfs/usr/lib/*/libatomic.so.1.* \
    /rootfs/usr/share/zoneinfo

# Stage 3: Final minimal runtime — scratch + trimmed cc + CNB user + UTC tz
FROM scratch

ARG CNB_USER_ID=1002
ARG CNB_GROUP_ID=1000

# Trimmed distroless/cc: glibc + libstdc++ + libgcc_s, no SSL, no CA bundle
COPY --from=cc-trimmer /rootfs/ /

# CNB user/group — overwrite distroless defaults
COPY --from=ubuntu-setup /etc/passwd /etc/passwd
COPY --from=ubuntu-setup /etc/group  /etc/group

# UTC zone only — covers native code that probes /usr/share/zoneinfo directly.
# Java's own TZDB handles everything else.
COPY --from=ubuntu-setup /usr/share/zoneinfo/UTC        /usr/share/zoneinfo/UTC
COPY --from=ubuntu-setup /usr/share/zoneinfo/Etc/UTC    /usr/share/zoneinfo/Etc/UTC
COPY --from=ubuntu-setup /usr/share/zoneinfo/Etc/UCT    /usr/share/zoneinfo/Etc/UCT
COPY --from=ubuntu-setup /usr/share/zoneinfo/posixrules /usr/share/zoneinfo/posixrules

LABEL io.buildpacks.stack.id="io.buildpacks.stacks.noble"
LABEL io.buildpacks.base.distro.name="distroless"
LABEL io.buildpacks.base.distro.version="cc"
LABEL maintainer="patbaumgartner"
LABEL org.opencontainers.image.source="https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny"
LABEL org.opencontainers.image.description="Run stack image for the Distroless Buildpack Builder Java Tiny (Google Distroless cc, SSL-stripped)"

USER ${CNB_USER_ID}:${CNB_GROUP_ID}
