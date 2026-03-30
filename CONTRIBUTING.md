# Contributing

## How to Contribute

### Reporting bugs

Open a [GitHub Issue](https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny/issues/new) with:
- Steps to reproduce
- Expected vs. actual behaviour
- Your `pack version` and `docker version` output

### Submitting changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes (see guidelines below)
4. Run smoke tests: `make test-smoke`
5. Open a Pull Request against `main`

## Development Setup

| Tool | Min version |
|------|------------|
| Docker | 20.10 |
| [pack CLI](https://buildpacks.io/docs/tools/pack/) | 0.33 |
| Java / Maven | JDK 21+ (for Java samples) |
| make | any |
| hadolint (optional) | 2.x |

```bash
git clone https://github.com/patbaumgartner/distroless-buildpack-builder-java-tiny.git
cd distroless-buildpack-builder-java-tiny

make build-stack    # Build stack images (requires Docker)
make build-builder  # Assemble the CNB builder (requires pack)
make test-smoke     # Run smoke tests
make test           # Run full integration tests
```

## Pull Request Guidelines

- All smoke tests must pass (`make test-smoke`)
- Run `make lint` and address Hadolint warnings
- Update `README.md` if you change public-facing behaviour
- Keep PRs focused on a single concern

## Commit Style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(stack): upgrade distroless to latest nonroot tag
fix(builder): correct lifecycle version constraint
chore(deps): bump ubuntu base image to 24.04
docs: add section on custom stack IDs
```

## Updating Buildpack Versions

Pinned versions in `builder.toml` are managed automatically by **Renovate**. To update manually:

1. Find the current tag on Docker Hub (e.g. `paketobuildpacks/java`)
2. Update the `uri` in the `[[buildpacks]]` block
3. Update the matching `version` in the `[[order.group]]` block
4. Build and test locally

## License

By contributing, you agree your contributions will be licensed under Apache 2.0.
