# Run stack image – minimal runtime base for CNB-built Java application images.
#
# Two-stage build: an Ubuntu helper copies distroless/cc into /rootfs, strips
# libraries Java never uses, and adds the CNB user. The final image is assembled
# FROM scratch using only that trimmed rootfs.
# Architecture-agnostic: usr/lib/*/ globs cover both amd64 and arm64.

# Stage 1: Trim distroless/cc
# The distroless/cc image bundles OpenSSL (libssl3 + libcrypto, ~4 MB), a full CA
# certificate bundle, and libgomp, which a JVM-only workload never dlopens.
# Because distroless has no shell we cannot run rm inside it directly;
# instead we copy its entire filesystem into /rootfs inside an Ubuntu helper layer,
# delete the dead-weight files, and hand /rootfs to the scratch stage below.
FROM gcr.io/distroless/cc:nonroot@sha256:c31ff9abcb1910f3ab25c7957bdaf0bfe12a01eb546e8df2282f1c8f682b606c AS distroless-src
# hadolint ignore=DL3006
FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS cc-trimmer

ARG CNB_USER_ID=1002
ARG CNB_GROUP_ID=1000

COPY --from=distroless-src / /rootfs/
COPY --chmod=0755 trim-rootfs.sh /usr/local/bin/trim-rootfs
RUN /usr/local/bin/trim-rootfs

# Stage 2: Final minimal runtime — scratch + trimmed cc
FROM scratch

ARG CNB_USER_ID=1002
ARG CNB_GROUP_ID=1000

# Trimmed distroless/cc: glibc + libstdc++ + libgcc_s, no SSL, no CA bundle
COPY --from=cc-trimmer /rootfs/ /

LABEL io.buildpacks.stack.id="io.buildpacks.stacks.noble"
LABEL io.buildpacks.base.distro.name="distroless"
LABEL io.buildpacks.base.distro.version="cc"
LABEL maintainer="patbaumgartner"
LABEL org.opencontainers.image.source="https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny"
LABEL org.opencontainers.image.description="Run stack image for the Distroless Buildpack Builder Java Tiny (Google Distroless cc, SSL-stripped)"

USER ${CNB_USER_ID}:${CNB_GROUP_ID}
