# Sample: Java / Spring Boot (JVM)

Minimal Spring Boot web application that demonstrates the distroless buildpack builder with a standard JVM runtime.

## Endpoints

| Path | Description |
|------|-------------|
| `GET /` | Returns a greeting string |
| `GET /health` | Returns `OK` |

## Build with pack CLI

```bash
pack build my-java-app \
  --path . \
  --builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Build with Maven

```bash
mvn spring-boot:build-image
```

## Run

```bash
docker run --rm -p 8080:8080 my-java-app
curl http://localhost:8080/
```

## Build environment variables

See `project.toml` for buildpack configuration:

| Variable | Value | Purpose |
|----------|-------|---------|
| `BP_DIRECT_PROCESS` | `true` | Direct process launch (no shell) |
| `BP_JVM_VERSION` | `25` | Target JDK version |
| `BP_JVM_JLINK_ENABLED` | `true` | Generate minimal custom JRE with jlink |

## Tests

```bash
mvn test
```

Runs endpoint-level integration tests using Spring MockMvc.

## Runtime Constraints

This sample is built for the distroless run image profile used by this repository.
Review runtime compatibility notes in the root README before using this pattern
for workloads that depend on system SSL/CA bundles or extra native libraries.
