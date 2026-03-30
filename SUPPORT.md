# Support

## Getting Help

- **Documentation** — start with [README.md](README.md) for usage and [CONTRIBUTING.md](CONTRIBUTING.md) for development setup.
- **Bug reports** — open a [GitHub Issue](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/issues/new?template=bug_report.md).
- **Feature requests** — open a [GitHub Issue](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/issues/new?template=feature_request.md).
- **Security vulnerabilities** — see [SECURITY.md](SECURITY.md) (do **not** open a public issue).

## Compatibility

| Component | Minimum version |
|-----------|----------------|
| Docker | 20.10 |
| pack CLI | 0.33 |
| Java / Maven | JDK 25+ (for sample apps) |

## Scope

This project provides a **CNB builder image** and supporting stack images. It does **not** include:

- Application source code beyond the integration test samples
- JDK or GraalVM distributions (these are resolved by the Paketo buildpacks at build time)
- Runtime monitoring or APM tooling (see the Cost and Capacity section in README.md for guidance)
