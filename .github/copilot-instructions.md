# Copilot Instructions – Distroless Buildpack Builder (Java Tiny)

## Architecture

| Component | Base Image | Purpose |
|-----------|-----------|---------|
| Build stack | `ubuntu:24.04` | Full toolchain for compiling Java apps |
| Run stack | `gcr.io/distroless/cc:nonroot` | Minimal, shell-free Java runtime |
| Builder | CNB lifecycle + Paketo Java Buildpacks | Orchestrates builds via `pack` CLI |

## Key Files

- `builder.toml` — CNB builder config (lifecycle version, Java buildpacks, detection order, stack images)
- `stack/build/Dockerfile` — Build-phase stack image (Ubuntu 24.04, Java-focused deps)
- `stack/run/Dockerfile` — Run-phase stack image (Google Distroless, minimal Java runtime)
- `Makefile` — Local build automation
- `renovate.json5` — Renovate config for `builder.toml` version tracking (custom regex manager)
- `.github/dependabot.yml` — Dependabot for Actions, Docker, Maven

## Sample Applications

All samples in `samples/` expose `/` and `/health` on port `8080`:

| Directory | Language |
|-----------|----------|
| `samples/java` | Java 25 / Spring Boot (also supports `mvn spring-boot:build-image`) |
| `samples/java-native-image` | Java 25 / GraalVM Native Image |

When adding a new sample, update:
1. `.github/workflows/benchmark.yml` — add to the matrix
2. `.github/workflows/test.yml` — add pack build + container verification steps
3. `.github/dependabot.yml` — add dependency tracking for the ecosystem
4. `tests/integration/test_builder.sh` — add to the test loop
5. `README.md` — samples table

## CI/CD Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| Build and Push | `build-and-push.yml` | Build stack images + builder, push to GHCR + Docker Hub |
| Integration Tests | `test.yml` | Smoke tests (CNB labels) → integration tests (pack + mvn) |
| Security Scan | `security-scan.yml` | Trivy CVE scan + Hadolint Dockerfile lint |
| OSSF Scorecard | `scorecard.yml` | Supply-chain security posture (weekly) |
| Benchmark | `benchmark.yml` | Build-time + image-size benchmarks for Java samples |
| Release | `release.yml` | GitHub Release on version tags (`v*`) |

## Conventions

- **Secrets**: Docker Hub credentials → `DOCKER_USERNAME` / `DOCKER_PASSWORD`
- **Env vars**: Workflows define `IMAGE_BASE` for the full GHCR image path
- **Trivy**: Pinned to a specific version in `security-scan.yml`
- **Commit messages**: Conventional commits (`chore:`, `feat:`, `fix:`, `ci:`, `docs:`)
- **Dependency updates**: Dependabot handles Actions, Docker, Maven; Renovate handles `builder.toml` (buildpacks + lifecycle)

## Building Locally

```bash
make build-stack    # Build stack images
make build-builder  # Create CNB builder
make test           # Run smoke + integration tests
```

## Creating a Release

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Triggers `release.yml` (GitHub Release) and `build-and-push.yml` (versioned images).
