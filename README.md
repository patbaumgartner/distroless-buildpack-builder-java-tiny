# distroless-buildpack-builder-java-tiny

[![Build and Push](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/build-and-push.yml)
[![Integration Tests](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/test.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/test.yml)
[![Quality Gates](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/quality-gates.yml/badge.svg)](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/actions/workflows/quality-gates.yml)
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
  --builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest \
  --path ./my-java-app
```

### Set as default builder

```bash
pack config default-builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest
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
      <builder>ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest</builder>
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
  -Dspring-boot.build-image.builder=ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Images

Images are published to **GHCR** on every push to `main` and on version tags. The run image is also rebuilt nightly to pick up base image security patches. GHCR images include [SLSA](https://slsa.dev/) build provenance attestations.

| Image | Registry |
|-------|----------|
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
  --builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Repository Structure

```text
├── builder.toml              # CNB builder configuration
├── Makefile                  # Local build automation
├── openrewrite/rewrite.yml   # Shared OpenRewrite recipes
├── benchmarks/budgets.json   # Performance SLO budgets
├── stack/
│   ├── build/Dockerfile      # Build stack (Ubuntu 24.04)
│   └── run/Dockerfile        # Run stack (Google Distroless)
├── samples/
│   ├── java/                 # Spring Boot (JVM)
│   └── java-native-image/    # Spring Boot (GraalVM Native Image)
├── tests/
│   ├── integration/          # End-to-end builder tests
│   └── smoke/                # Fast label + config validation
└── .github/
    ├── dependabot.yml
    └── workflows/
        ├── build-and-push.yml
        ├── test.yml
        ├── quality-gates.yml
        ├── security-scan.yml
        ├── scorecard.yml
        ├── benchmark.yml
        ├── openrewrite.yml
        ├── dependency-policy-review.yml
        └── release.yml
```

## CI/CD

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **Build and Push** | push to `main`, version tags | Build stack images + builder, push to GHCR |
| **Integration Tests** | push, pull_request | Smoke tests → integration tests (pack + mvn) |
| **Quality Gates** | push, pull_request | ShellCheck, actionlint, markdownlint, OpenRewrite, Checkstyle, tests |
| **Security Scan** | push, pull_request, weekly | Hadolint, Trivy filesystem + image scans |
| **OSSF Scorecard** | push to `main`, weekly | Supply-chain security posture analysis |
| **Benchmark** | after Build and Push, weekly | Build times, image sizes, runtime metrics |
| **OpenRewrite** | monthly, manual | Auto-apply code cleanup recipes, create PRs |
| **Dependency Policy Review** | quarterly, manual | Governance audit checklist |
| **Release** | version tags (`v*`) | GitHub Release with pull instructions |

## Quality Contract

Every pull request must pass the checks below. Each check exists for a single, specific reason — there is no overlap.

| Check | Workflow | What it proves |
|-------|----------|----------------|
| ShellCheck | Quality Gates | Shell scripts follow best practices and avoid common bugs |
| actionlint | Quality Gates | GitHub Actions workflow syntax is valid |
| markdownlint | Quality Gates | Documentation formatting is consistent |
| OpenRewrite dry-run | Quality Gates | Code matches the shared cleanup recipe (no uncommitted rewrites) |
| Checkstyle | Quality Gates | Java source follows Google style conventions |
| Unit tests (`mvn test`) | Quality Gates | Sample endpoint contracts (`/` and `/health`) hold |
| Hadolint | Security Scan | Dockerfiles follow best-practice lint rules |
| Trivy (filesystem + image) | Security Scan | No known CVEs in dependencies or built images |
| Smoke tests | Integration Tests | Stack image labels, UIDs, and `builder.toml` structure are correct |
| Integration tests | Integration Tests | Builder produces a runnable container that responds on `/` |

If a check does not appear in this table, it should not be in CI. If a claim appears in documentation, it should map to one of these checks.

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

## Should I Use This Builder?

| Scenario | Recommendation |
|----------|---------------|
| Spring Boot REST API / microservice | **Yes** — ideal workload, minimal footprint |
| Spring Boot with GraalVM Native Image | **Yes** — fastest startup, smallest image |
| App that needs outbound HTTPS/TLS calls via system SSL | **No** — the run image strips OpenSSL and CA certificates; the JVM's built-in TLS stack works, but Native Image binaries linking against system `libssl` will fail |
| App that writes to the local filesystem at runtime | **Caution** — limited writable paths; design for stateless operation |
| App that requires a shell for debugging or exec-ing into the container | **No** — the run image has no shell by design |
| Non-Java workloads (Go, Rust, Node.js) | **No** — this builder only ships Java and Java Native Image buildpacks |

### Workload Compatibility

The trimmed run image includes `glibc`, `libstdc++`, and `libgcc_s` — enough for the JVM and ahead-of-time compiled Native Image binaries. The following components are **intentionally removed** to minimise size and attack surface:

- OpenSSL (`libssl3`, `libcrypto3`) and CA certificates
- `libgomp`, `libitm`, `libatomic`
- Full timezone database (only UTC is included; Java uses its own bundled TZDB)

If your workload depends on system-level TLS or these libraries, use the standard `paketobuildpacks/builder-jammy-tiny` builder instead, or open a feature request for a TLS-compatible run image variant.

## Cost and Capacity

One key benefit of smaller, distroless images is **lower infrastructure cost**. Here's how to measure and act on it:

### Key Metrics to Monitor

| Metric | What to watch | Action threshold |
|--------|--------------|-----------------|
| **Image size** | Compressed pull size (check `docker manifest inspect`) | Alert if >50% larger than baseline |
| **Container RSS** | Resident Set Size via `docker stats` or Prometheus `container_memory_rss` | Alert if steady-state exceeds requested memory ×0.8 |
| **JVM heap** | `-XX:MaxRAMPercentage` (default 25%) of container memory limit | Tune if GC pause time or OOM kills increase |
| **Startup time** | Time from container start to first HTTP 200 on `/health` | JVM: <10s, Native Image: <1s |
| **CPU throttling** | `container_cpu_cfs_throttled_seconds_total` in Prometheus | Increase CPU limit or optimise hot paths |
| **Image pull time** | CI or Kubernetes pull duration | Smaller images = faster rollouts and autoscaling |

### Sizing Guidance

| Mode | Suggested starting limits | Expected image size |
|------|--------------------------|-------------------|
| JVM (jlink) | 512 Mi memory, 500m CPU | ~100–140 MB |
| Native Image | 128 Mi memory, 250m CPU | ~80–120 MB |

### When Your App Gets Expensive

If you notice resource consumption growing over time:

1. **Check for memory leaks** — compare heap dumps across releases
2. **Review dependency growth** — new libraries add startup time and memory; use `mvn dependency:tree` to audit
3. **Profile GC behaviour** — switch to ZGC or Shenandoah if pause times matter
4. **Consider Native Image** — for workloads where startup time and baseline memory dominate cost
5. **Track image size in CI** — the Benchmark workflow already does this; set an alert threshold

### Reproducing Benchmarks Locally

```bash
# Build-time benchmark (3 iterations)
for i in 1 2 3; do
  time pack build bench-app \
    --path ./samples/java \
    --builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest \
    --clear-cache
done

# Image size comparison
docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep bench-app
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Engineering Review

An in-depth software craftsmanship review of this repository is available at
[docs/REPOSITORY_REVIEW.md](docs/REPOSITORY_REVIEW.md).

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Support

See [SUPPORT.md](SUPPORT.md).

## License

Apache 2.0 — see [LICENSE](LICENSE).
