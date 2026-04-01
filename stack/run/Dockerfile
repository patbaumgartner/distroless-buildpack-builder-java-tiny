# Run stack image – used as the runtime base for built application images.
#
# Stage 1 (ubuntu-setup): CNB user/group + tzdata source (UTC only).
# Stage 2 (cc-trimmer):   Copies distroless/cc to /rootfs inside an Ubuntu layer,
#                          then strips packages that Java never uses (~4–5 MB):
#                            • libssl3 + libcrypto  — Java uses JSSE (pure-Java TLS)
#                            • CA certificate bundle — Java uses $JAVA_HOME/lib/security/cacerts
#                            • libgomp              — OpenMP, not used by standard JVM workloads
#                            • libitm + libatomic   — GCC extras not required by HotSpot
#                            • full zoneinfo tree   — replaced by UTC-only slices from stage 1
# Stage 3 (final):        FROM scratch assembled from the trimmed cc rootfs + CNB user + UTC tz.
#
# Glob patterns (usr/lib/*/) keep stage 2 architecture-agnostic so the same
# Dockerfile works for linux/amd64 (x86_64-linux-gnu) and linux/arm64 (aarch64-linux-gnu).

# Stage 1: Ubuntu setup — CNB user/group and tzdata extraction
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
FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c AS cc-trimmer
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
