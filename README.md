# distroless-buildpack-builder-java-tiny

[![Build and Push](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/build-and-push.yml)
[![Integration Tests](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/test.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/test.yml)
[![Security Scan](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/security-scan.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/security-scan.yml)

A [Cloud Native Buildpacks](https://buildpacks.io) builder optimised for **Java** (JVM and GraalVM Native Image) that produces minimal, secure application images using [Google Distroless](https://github.com/GoogleContainerTools/distroless) as the runtime base.

Inspired by the `paketo-buildpacks/builder-jammy-tiny` philosophy: only the dependencies that Java actually needs, nothing more.

| Component | Base image | Purpose |
|-----------|-----------|---------|
| **Build stack** | `ubuntu:24.04` | Full toolchain for compiling Java apps |
| **Run stack** | `gcr.io/distroless/cc:nonroot` | Minimal, shell-free Java runtime |
| **Builder** | CNB lifecycle + Paketo Java Buildpacks | Orchestrates builds |

The run image has **no shell, no package manager, no debug tools** — drastically reducing the attack surface of every Java container built with this builder.

## Supported Languages

| Language | Buildpack |
|----------|-----------|
| Java / Spring Boot | `paketo-buildpacks/java` |
| Java Native Image (GraalVM) | `paketo-buildpacks/java-native-image` |

## Quick Start

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/) ≥ 20.10, [pack CLI](https://buildpacks.io/docs/tools/pack/) ≥ 0.33

```bash
pack build my-java-app \
  --builder patbaumgartner/distroless-buildpack-builder-java-tiny:latest \
  --path ./my-java-app
```

### Set as default builder

```bash
pack config default-builder patbaumgartner/distroless-buildpack-builder-java-tiny:latest
pack build my-java-app
```

### Spring Boot with Maven

Configure once in `pom.xml`:

```xml
<plugin>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-maven-plugin</artifactId>
  <configuration>
    <image>
      <builder>patbaumgartner/distroless-buildpack-builder-java-tiny:latest</builder>
      <pullPolicy>IF_NOT_PRESENT</pullPolicy>
      <env>
        <BP_JVM_JLINK_ENABLED>true</BP_JVM_JLINK_ENABLED>
      </env>
    </image>
  </configuration>
</plugin>
```

Then build:

```bash
mvn spring-boot:build-image

# or override the builder without changing pom.xml:
mvn spring-boot:build-image \
  -Dspring-boot.build-image.builder=patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Images

Images are published to **Docker Hub** and **GHCR** on every push to `main` and on version tags. All images include SBOM and [SLSA](https://slsa.dev/) provenance attestations.

| Image | Registry |
|-------|----------|
| `patbaumgartner/distroless-buildpack-builder-java-tiny` | Docker Hub |
| `patbaumgartner/distroless-buildpack-builder-java-tiny-build` | Docker Hub |
| `patbaumgartner/distroless-buildpack-builder-java-tiny-run` | Docker Hub |
| `ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny` | GHCR |
| `ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny/build` | GHCR |
| `ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny/run` | GHCR |

## Building Locally

**Prerequisites:** Docker with buildx, pack CLI, `make`

```bash
make build-stack    # Build + push multi-arch stack images (amd64, arm64)
make build-builder  # Assemble the CNB builder image
make test           # Run smoke + integration tests
make test-smoke     # Run smoke tests only (fast)
```

> **Note:** `make build-stack` uses `docker buildx build --push` to produce multi-arch images (`linux/amd64` + `linux/arm64`). It pushes directly to the registry — local loading of multi-platform images is not supported by Docker. Set `PLATFORMS=linux/amd64` to restrict to a single architecture.

## Sample Applications

All samples in `samples/` expose `/` and `/health` on port `8080`.

| Sample | Language |
|--------|----------|
| `samples/java` | Java 25 / Spring Boot |
| `samples/java-native-image` | Java 25 / GraalVM Native Image |

Build a sample:

```bash
pack build my-app \
  --path ./samples/java \
  --builder patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Repository Structure

```
├── builder.toml              # CNB builder configuration
├── Makefile                  # Local build automation
├── stack/
│   ├── build/Dockerfile      # Build stack image (Ubuntu 24.04)
│   └── run/Dockerfile        # Run stack image (Google Distroless)
├── samples/                  # Ready-to-build Java sample apps
│   ├── java/                 # Spring Boot (JVM)
│   └── java-native-image/    # Spring Boot (GraalVM Native Image)
├── tests/
│   ├── integration/          # End-to-end builder tests
│   └── smoke/                # Fast label + config validation
└── .github/
    ├── dependabot.yml        # Automated dependency updates
    └── workflows/
        ├── build-and-push.yml  # Build + push to GHCR and Docker Hub
        ├── test.yml            # Smoke + integration tests
        ├── security-scan.yml   # Trivy CVE scan + Hadolint lint
        ├── scorecard.yml       # OSSF Scorecard (weekly)
        ├── benchmark.yml       # Build-time + image-size benchmarks
        └── release.yml         # GitHub releases on version tags
```

## CI/CD

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **Build and Push** | push to `main`, version tags | Build stack images + builder, push to GHCR and Docker Hub |
| **Integration Tests** | push, pull_request | Smoke tests → integration tests (pack + mvn) |
| **Security Scan** | push, pull_request, weekly | Trivy CVE scan + Hadolint Dockerfile lint |
| **OSSF Scorecard** | push to `main`, weekly | Supply-chain security posture analysis |
| **Benchmark** | after Build and Push, weekly | Build times + image sizes for Java samples |
| **Release** | version tags (`v*`) | GitHub Release with pull instructions |

## Security

The run image (`gcr.io/distroless/cc:nonroot`) provides:

- No shell — attackers cannot execute shell commands
- No package manager — nothing installable at runtime
- Non-root user (uid 1002) by default
- C++ runtime (`libstdc++`, `libgcc`) included for JVM and native binary support

Automated scanning on every push:

- **Trivy** — CVE scanning of container images and filesystem
- **Hadolint** — Dockerfile best-practice linting
- **OSSF Scorecard** — Supply-chain security posture (weekly)

SARIF reports are published to the [Security tab](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/security/code-scanning).

See [SECURITY.md](SECURITY.md) for the vulnerability disclosure policy.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](LICENSE).