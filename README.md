# docker-base

Multi-arch base Docker images for Utopia PHP libraries, built on Alpine with Swoole and a curated set of PHP extensions.

## Supported PHP versions

- PHP 8.3
- PHP 8.4
- PHP 8.5

Each version is published as a multi-arch image (`linux/amd64`, `linux/arm64`).

## Tags

Images are published to [`appwrite/utopia-base`](https://hub.docker.com/r/appwrite/utopia-base) on Docker Hub.

| Tag | Source | Stability |
| --- | --- | --- |
| `php-<X.Y>-<release>` | `release.yml` on a published GitHub release | Stable — pin to this in production |
| `php-<X.Y>-<sha>` | `publish.yml` on every push to `main` after CI passes | Tracks `main` — useful for testing, garbage-collected after 14 days |

`<X.Y>` is one of `8.3`, `8.4`, `8.5`. `<release>` is the GitHub release tag (e.g. `0.5.0`). `<sha>` is the full 40-char commit SHA.

## CI/CD

Four workflows:

- **`ci.yml`** — runs on PRs, pushes to `main`, and weekly. Builds each `(php × arch)` once, shares the image via artifact, then runs structure tests, [dive](https://github.com/wagoodman/dive) efficiency checks, and [Trivy](https://github.com/aquasecurity/trivy) CVE scans against the artifact. SARIF results upload to the Security tab.
- **`publish.yml`** — `workflow_run`-triggered after CI succeeds on `main`. Pushes per-arch tags and assembles the multi-arch manifest under `php-<X.Y>-<sha>`. No rebuild — uses CI's artifacts.
- **`release.yml`** — triggered by `release: published`. Promotes the existing `php-<X.Y>-<sha>` manifest to `php-<X.Y>-<release-tag>` via `docker buildx imagetools create`. No rebuild.
- **`cleanup.yml`** — daily cron. Deletes `php-<X.Y>-<sha>[-arch]` tags older than 14 days from Docker Hub. Release tags don't match the regex and are never touched.

All publishing workflows share a `build-<sha>` concurrency group so a release queues behind in-flight CI on the same commit.

## Local development

```sh
docker build -t utopia-base-test php-8.4/.
container-structure-test test --image utopia-base-test --config php-8.4/tests.yaml
```
