#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REGISTRY="${REGISTRY:-ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny}"
BUILD_IMAGE="${BUILD_IMAGE:-${REGISTRY}/build:latest}"
RUN_IMAGE="${RUN_IMAGE:-${REGISTRY}/run:latest}"
BUILDER_IMAGE="${REGISTRY}:latest"
EXPECTED_STACK_ID="io.buildpacks.stacks.noble"

PASS=0
FAIL=0

info()  { echo "ℹ  $*"; }
pass()  { echo "✔  $*"; PASS=$((PASS + 1)); }
fail()  { echo "✘  $*" >&2; FAIL=$((FAIL + 1)); }

check_label() {
  local image="$1"
  local label="$2"
  local expected="$3"

  local actual
  actual=$(docker inspect --format "{{ index .Config.Labels \"${label}\" }}" "${image}" 2>/dev/null)

  if [[ "${actual}" == "${expected}" ]]; then
    pass "${image}: label '${label}' = '${actual}'"
  else
    fail "${image}: label '${label}' expected '${expected}', got '${actual}'"
  fi
}

check_image_user() {
  local image="$1"
  local expected_uid="$2"

  local actual
  actual=$(docker inspect --format "{{ .Config.User }}" "${image}" 2>/dev/null)

  if [[ "${actual}" == *"${expected_uid}"* ]]; then
    pass "${image}: user contains expected uid '${expected_uid}'"
  else
    fail "${image}: user expected to contain '${expected_uid}', got '${actual}'"
  fi
}

# ---------------------------------------------------------------------------
# 1. Stack images – label checks
# ---------------------------------------------------------------------------
info "Checking stack image labels..."

if docker image inspect "${BUILD_IMAGE}" >/dev/null 2>&1; then
  check_label "${BUILD_IMAGE}" "io.buildpacks.stack.id" "${EXPECTED_STACK_ID}"
else
  fail "Build image not found locally: ${BUILD_IMAGE} (run 'make build-stack' first)"
fi

if docker image inspect "${RUN_IMAGE}" >/dev/null 2>&1; then
  check_label "${RUN_IMAGE}" "io.buildpacks.stack.id" "${EXPECTED_STACK_ID}"
  check_label "${RUN_IMAGE}" "io.buildpacks.base.distro.name" "distroless"
  check_image_user "${RUN_IMAGE}" "1002"
else
  fail "Run image not found locally: ${RUN_IMAGE} (run 'make build-stack' first)"
fi

# ---------------------------------------------------------------------------
# 2. builder.toml validation (pack inspect-builder if builder is available)
# ---------------------------------------------------------------------------
info "Validating builder.toml..."

BUILDER_TOML="${REPO_ROOT}/builder.toml"

# Modern builder.toml uses [build] + [[run.images]] instead of the deprecated [stack].
if grep -q '\[build\]' "${BUILDER_TOML}"; then
  pass "builder.toml contains [build] section (modern format)"
elif grep -q '\[stack\]' "${BUILDER_TOML}"; then
  pass "builder.toml contains [stack] section (legacy format)"
else
  fail "builder.toml is missing both [build] and [stack] sections"
fi

if grep -q 'image\s*=' "${BUILDER_TOML}" || grep -q 'build-image' "${BUILDER_TOML}"; then
  pass "builder.toml contains build image reference"
else
  fail "builder.toml is missing build image reference"
fi

if grep -qE 'run\.images|run-image' "${BUILDER_TOML}"; then
  pass "builder.toml contains run image reference"
else
  fail "builder.toml is missing run image reference"
fi

# Description must be non-empty
if grep -qE '^description\s*=\s*".+"' "${BUILDER_TOML}"; then
  pass "builder.toml has a non-empty description"
else
  fail "builder.toml is missing or has an empty description"
fi

# Lifecycle version must be set and follow semver (major.minor.patch)
LIFECYCLE_VERSION=$(grep -oP 'version\s*=\s*"\K[0-9]+\.[0-9]+\.[0-9]+' "${BUILDER_TOML}" | head -1)
if [[ -n "${LIFECYCLE_VERSION}" ]]; then
  pass "builder.toml lifecycle version is valid semver: ${LIFECYCLE_VERSION}"
else
  fail "builder.toml lifecycle version is missing or not valid semver"
fi

# Buildpack URIs must use docker:// prefix
BUILDPACK_URIS=$(grep -oP 'uri\s*=\s*"\K[^"]+' "${BUILDER_TOML}")
if [[ -n "${BUILDPACK_URIS}" ]]; then
  all_docker=true
  while IFS= read -r uri; do
    if [[ "${uri}" != docker://* ]]; then
      fail "builder.toml buildpack URI missing docker:// prefix: ${uri}"
      all_docker=false
    fi
  done <<< "${BUILDPACK_URIS}"
  if [[ "${all_docker}" == "true" ]]; then
    pass "All buildpack URIs use docker:// prefix"
  fi
else
  fail "builder.toml has no buildpack URIs defined"
fi

# Each [[order.group]] id+version must match a [[buildpacks]] entry
ORDER_IDS=$(grep -A2 '\[\[order\.group\]\]' "${BUILDER_TOML}" | grep 'id' | grep -oP '"\K[^"]+')
ORDER_VERSIONS=$(grep -A2 '\[\[order\.group\]\]' "${BUILDER_TOML}" | grep 'version' | grep -oP '"\K[^"]+')
if [[ -n "${ORDER_IDS}" ]]; then
  # Build array of expected buildpack patterns from order groups
  mapfile -t IDS <<< "${ORDER_IDS}"
  mapfile -t VERS <<< "${ORDER_VERSIONS}"
  for idx in "${!IDS[@]}"; do
    BP_ID="${IDS[$idx]}"
    BP_VER="${VERS[$idx]:-}"
    # The URI contains the buildpack name (last path segment) and version after ':'
    BP_SHORT="${BP_ID##*/}"
    if echo "${BUILDPACK_URIS}" | grep -q "${BP_SHORT}:${BP_VER}"; then
      pass "Order group '${BP_ID}:${BP_VER}' matches a buildpack URI"
    else
      fail "Order group '${BP_ID}:${BP_VER}' has no matching buildpack URI"
    fi
  done
fi

# Targets must define os and arch
TARGET_COUNT=$(grep -c '\[\[targets\]\]' "${BUILDER_TOML}" 2>/dev/null || echo "0")
if [[ "${TARGET_COUNT}" -gt 0 ]]; then
  pass "builder.toml defines ${TARGET_COUNT} target platform(s)"
else
  info "builder.toml does not define explicit targets (using defaults)"
fi

# ---------------------------------------------------------------------------
# 3. Builder image (if available)
# ---------------------------------------------------------------------------
if docker image inspect "${BUILDER_IMAGE}" >/dev/null 2>&1; then
  info "Inspecting builder image..."
  if pack builder inspect "${BUILDER_IMAGE}" >/dev/null 2>&1; then
    pass "${BUILDER_IMAGE}: pack builder inspect succeeded"
  else
    fail "${BUILDER_IMAGE}: pack builder inspect failed"
  fi
else
  info "Builder image not found locally – skipping builder inspect"
fi

# ---------------------------------------------------------------------------
# 4. Dockerfile syntax check
# ---------------------------------------------------------------------------
if command -v hadolint >/dev/null 2>&1; then
  info "Running hadolint on Dockerfiles..."
  for df in "${REPO_ROOT}/stack/build/Dockerfile" "${REPO_ROOT}/stack/run/Dockerfile"; do
    if hadolint "${df}" 2>&1; then
      pass "${df}: hadolint passed"
    else
      fail "${df}: hadolint reported issues"
    fi
  done
else
  info "hadolint not found – skipping Dockerfile lint"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "-------------------------------"
echo "Smoke test results: ${PASS} passed, ${FAIL} failed"
echo "-------------------------------"

[[ "${FAIL}" -eq 0 ]]
