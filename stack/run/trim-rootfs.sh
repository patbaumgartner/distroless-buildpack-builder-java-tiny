#!/usr/bin/env bash
#
# Trims the Google Distroless `cc` filesystem staged at /rootfs down to what a
# JVM or GraalVM Native Image workload actually needs, and installs the CNB user.
#
# Every removal is bracketed by an assertion: the path MUST exist before it is
# deleted and MUST be gone afterwards. A silently-missing path means upstream
# moved or renamed it, and the image would then ship a component the README
# promises is absent. That must fail the build loudly rather than degrade
# quietly, which is exactly how the previous denylist rotted: five of its
# thirteen patterns had stopped matching anything.

set -euo pipefail

ROOTFS=/rootfs
CNB_USER_ID="${CNB_USER_ID:?}"
CNB_GROUP_ID="${CNB_GROUP_ID:?}"

cd "${ROOTFS}"

require() {
  local pattern="$1"
  if ! compgen -G "${pattern}" >/dev/null; then
    echo "ASSERTION FAILED: expected '${pattern}' to exist in distroless/cc before trimming." >&2
    echo "Upstream layout changed. Review the trim list instead of shipping an untrimmed image." >&2
    exit 1
  fi
}

refute() {
  local pattern="$1"
  if compgen -G "${pattern}" >/dev/null; then
    echo "ASSERTION FAILED: '${pattern}' still present after trimming." >&2
    exit 1
  fi
}

# OpenSSL. The JVM implements TLS in Java (SunJSSE) and GraalVM embeds the JDK
# trust store, so neither dlopens these. Workloads that DO need system OpenSSL
# (Netty tcnative, Conscrypt) are explicitly out of scope; see the README.
TRIM_GLOBS=(
  'usr/lib/*/libssl.so.3*'
  'usr/lib/*/libcrypto.so.3*'
  'usr/lib/*/engines-3'
  'usr/lib/*/libgomp.so.1*'
  'etc/ssl'
  'usr/share/zoneinfo'
)

# Java ships its own TZDB, but native code may still probe /usr/share/zoneinfo.
# Preserve real UTC from distroless itself rather than importing a foreign
# distribution's tzdata: the previous version copied Ubuntu's `posixrules`,
# which is a symlink to America/New_York that Docker COPY dereferences, so the
# "UTC only" image actually shipped US Eastern DST rules.
install -D -m 0644 usr/share/zoneinfo/Etc/UTC /tmp/UTC

for glob in "${TRIM_GLOBS[@]}"; do
  require "${glob}"
done

for glob in "${TRIM_GLOBS[@]}"; do
  # shellcheck disable=SC2086 # deliberate glob expansion
  rm -rf ${glob}
done

for glob in "${TRIM_GLOBS[@]}"; do
  refute "${glob}"
done

install -D -m 0644 /tmp/UTC usr/share/zoneinfo/Etc/UTC
ln -s Etc/UTC usr/share/zoneinfo/UTC
rm -f /tmp/UTC

# dpkg metadata for packages whose payload is now gone. Left in place it makes
# Syft emit an SBOM claiming OpenSSL 3.x is installed and Trivy report OpenSSL
# CVEs forever against a library that is not in the image.
for pkg in libssl3t64 libgomp1 tzdata-legacy; do
  require "var/lib/dpkg/status.d/${pkg}"
  rm -f "var/lib/dpkg/status.d/${pkg}" "var/lib/dpkg/status.d/${pkg}.md5sums"
  rm -rf "usr/share/doc/${pkg}" "usr/share/lintian/overrides/${pkg}"
done

# CNB runtime user. Append to distroless's own passwd/group instead of
# overwriting them with a foreign distribution's copy, which would delete the
# upstream nonroot/nobody entries.
echo "cnb:x:${CNB_USER_ID}:${CNB_GROUP_ID}::/home/cnb:/sbin/nologin" >>etc/passwd
echo "cnb:x:${CNB_GROUP_ID}:" >>etc/group

# Java resolves user.home from passwd; a home that does not exist breaks
# libraries that cache or write there.
install -d -m 0755 home/cnb
chown "${CNB_USER_ID}:${CNB_GROUP_ID}" home/cnb

echo "Trim complete. Remaining rootfs size: $(du -sh . | cut -f1)"
