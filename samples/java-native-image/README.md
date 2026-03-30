# Sample: Java / GraalVM Native Image

Minimal Spring Boot web application compiled as a GraalVM Native Image binary, demonstrating the distroless buildpack builder with ahead-of-time compilation.

## Endpoints

| Path | Description |
|------|-------------|
| `GET /` | Returns a greeting string |
| `GET /health` | Returns `OK` |

## Build with pack CLI

```bash
pack build my-native-app \
  --path . \
  --builder ghcr.io/patbaumgartner/distroless-buildpack-builder-java-tiny:latest
```

## Build with Maven

```bash
mvn spring-boot:build-image
```

## Run

```bash
docker run --rm -p 8080:8080 my-native-app
curl http://localhost:8080/
```

## Build environment variables

See `project.toml` for buildpack configuration:

| Variable | Value | Purpose |
|----------|-------|---------|
| `BP_DIRECT_PROCESS` | `true` | Direct process launch (no shell) |
| `BP_NATIVE_IMAGE` | `true` | Compile a GraalVM Native Image binary |
| `BP_JVM_VERSION` | `25` | Target GraalVM version |
| `BP_MAVEN_BUILD_ARGUMENTS` | `-Pnative -Dmaven.test.skip=true package` | Maven args for native profile |

## Tests

```bash
mvn test
```

Runs endpoint-level integration tests using Spring MockMvc.

## Notes

- Native Image compilation is resource-intensive (expect 4+ GB RAM, several minutes)
- The resulting container starts in milliseconds and uses significantly less memory than JVM mode
- Tests are skipped during the native image build phase (`-Dmaven.test.skip=true`) but should be run separately via `mvn test`

## Runtime Constraints

This sample is built for the distroless run image profile used by this repository.
Review runtime compatibility notes in the root README before using this pattern
for workloads that depend on system SSL/CA bundles or extra native libraries.
