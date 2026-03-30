# Copilot Instructions – Distroless Buildpack Builder (Java Tiny)

## Architecture

| Component | Base Image | Purpose |
|-----------|-----------|---------|
| Build stack | `ubuntu:24.04` | Full toolchain for compiling Java apps |
| Run stack | `gcr.io/distroless/cc:nonroot` | Minimal, shell-free Java runtime |
| Builder | CNB lifecycle + Paketo Java Buildpacks | Orchestrates builds via `pack` CLI |

Multi-arch: images are built for both `amd64` and `arm64` via `docker buildx`.

## Key Files

- `builder.toml` — CNB builder config (lifecycle version, Java buildpacks, detection order, stack images, `[[targets]]` for multi-arch)
- `stack/build/Dockerfile` — Build-phase stack image (Ubuntu 24.04)
- `stack/run/Dockerfile` — Run-phase stack image (Google Distroless)
- `Makefile` — Local build automation (`PLATFORMS`, `REGISTRY`, `TAG` overrides)
- `openrewrite/rewrite.yml` — Shared OpenRewrite composite recipe (`com.patbaumgartner.CodeCleanup`)
- `benchmarks/budgets.json` — Performance SLO budgets for CI enforcement
- `renovate.json5` — Renovate config with 3 custom regex managers for `builder.toml`
- `.github/dependabot.yml` — 5 update configs: GitHub Actions, Docker (build), Docker (run), Maven (java), Maven (java-native-image)
- `.markdownlint.yml` — Markdown lint config
- `.shellcheckrc` — ShellCheck config
- `.gitattributes` — LF line ending enforcement
- `CODEOWNERS` — Auto-assign reviewers

## Sample Applications

All samples in `samples/` expose `/` and `/health` on port `8080`:

| Directory | Language | Key Build Env Vars |
|-----------|----------|--------------------|
| `samples/java` | Java 25 / Spring Boot | `BP_DIRECT_PROCESS=true`, `BP_JVM_VERSION=25`, `BP_JVM_JLINK_ENABLED=true` |
| `samples/java-native-image` | Java 25 / GraalVM Native Image | `BP_DIRECT_PROCESS=true`, `BP_NATIVE_IMAGE=true`, `BP_JVM_VERSION=25` |

Each sample has:

- `pom.xml` — Spring Boot parent, Checkstyle (Google style), OpenRewrite (external `rewrite.yml`)
- `project.toml` — CNB build-time env vars
- `README.md` — Build/run instructions
- `src/test/java/demo/ApplicationTest.java` — `@SpringBootTest` + MockMvc tests for `/` and `/health`

When adding a new sample, update:

1. `.github/workflows/benchmark.yml` — add to the matrix
2. `.github/workflows/test.yml` — add pack build + container verification steps
3. `.github/workflows/quality-gates.yml` — add to the matrix
4. `.github/dependabot.yml` — add dependency tracking
5. `tests/integration/test_builder.sh` — add to the test loop
6. `README.md` — samples table

## CI/CD Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| Build and Push | `build-and-push.yml` | push to main, tags, nightly | Multi-arch stack images + builder, push to GHCR, SBOM, attestations |
| Integration Tests | `test.yml` | push, PR, manual | Smoke tests → integration tests (`pack build` + `mvn spring-boot:build-image`) |
| Quality Gates | `quality-gates.yml` | push, PR, manual | ShellCheck, actionlint, markdownlint, OpenRewrite dry-run, Checkstyle, tests |
| Security Scan | `security-scan.yml` | push, PR, weekly | Hadolint, Trivy filesystem + image scans, SARIF upload |
| OSSF Scorecard | `scorecard.yml` | push to main, weekly | Supply-chain security posture |
| Benchmark | `benchmark.yml` | after Build and Push, manual | Build-time, image-size, baseline comparison, runtime metrics |
| OpenRewrite | `openrewrite.yml` | monthly, manual | Auto-apply code cleanup recipes, create PRs |
| Dependency Policy Review | `dependency-policy-review.yml` | quarterly, manual | Governance audit checklist |
| Release | `release.yml` | version tags (`v*`) | Changelog, GitHub Release with docker pull instructions |

## Tests

- `tests/smoke/smoke_test.sh` — Validates stack image labels, image user (uid 1002), `builder.toml` structure, builder inspection, hadolint
- `tests/integration/test_builder.sh` — Parameterized via `BUILDER` env var, tests each sample: pack build → docker run → `wait_for_http()` → curl `/` for HTTP 200 + "hello"

## Community & Documentation

- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1
- `CONTRIBUTING.md` — Dev setup, commit style (Conventional Commits), PR guidelines
- `SUPPORT.md` — Support channels, compatibility matrix
- `SECURITY.md` — Vulnerability reporting, security design, supply chain

## Conventions

- **Env vars**: Workflows define `IMAGE_BASE` for the full GHCR image path
- **Java style**: Google Checkstyle, 2-space indentation
- **Code quality**: OpenRewrite via shared `openrewrite/rewrite.yml` recipe
- **Commit messages**: Conventional commits (`chore:`, `feat:`, `fix:`, `ci:`, `docs:`)
- **Dependency updates**: Dependabot handles Actions, Docker, Maven; Renovate handles `builder.toml`
- **Supply chain**: Base images by digest in production, SBOM generation with Syft, SLSA build provenance

## Building Locally

```bash
make build-stack       # Build multi-arch stack images (amd64 + arm64)
make build-stack-build # Build stack only
make build-stack-run   # Run stack only
make build-builder     # Create CNB builder
make test              # Run smoke + integration tests
make test-smoke        # Fast label/config validation only
```

## Creating a Release

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Triggers `release.yml` (GitHub Release) and `build-and-push.yml` (versioned images).
