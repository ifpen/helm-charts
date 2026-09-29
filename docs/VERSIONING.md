# Versioning and releases

This repository uses trunk-based development. `main` is the only long-lived
branch; every change is a short pull request. Direct pushes and bot commits to
`main` are disabled by branch protection.

## Release cycle

1. A pull request runs linting, templating, kubeconform, chart installation, and
   an image build without pushing.
2. `rc-release.yml` publishes one `-rc.<pull-request>.<run-attempt>` package
   for every changed chart. It updates the Helm index and adds one updatable
   installation comment to the pull request. The three newest RCs per chart are
   retained.
3. Merging the pull request adds conventional commits to the relevant
   release-please Release PR. A chart is stable only when its own Release PR
   is merged.
4. `release-please.yml` creates a component tag named
   `<chart>-<version>` (without `v`, which matches chart-releaser naming) and
   invokes `release.yml` in the same workflow. This is intentional: tags made
   with `GITHUB_TOKEN` do not start another workflow.
5. The publication job builds the chart (and its dependencies), attaches it to
   the GitHub Release, updates `gh-pages`, publishes linked images, and removes
   that chart's RC releases.

The first FileSender stable release is based at `3.10.0`. The manifest is
therefore intentionally initialized to `3.10.0`; use a `Release-As: 3.10.0`
footer in the first release commit if that exact version must be created.

## FileSender

`charts/filesender/Chart.yaml` follows the application major/minor:
`version: <FileSender x.y>.<chart patch>`, `appVersion: "<x.y>"`, and the
description starts with `FileSender v<x.y>`. `values.yaml:image.tag` is the
complete chart version and carries the `x-release-please-version` annotation.
The stable image is built as
`ghcr.io/ifpen/filesender:<chart-version>` and also receives `latest`.

Renovate updates `FILESENDER_VERSION` with `feat(filesender)` and a
`Release-As: <new version>.0` footer. Regex managers keep `appVersion`,
description, and image tag aligned. PHP, SimpleSAMLphp, AWS SDK, PostgreSQL,
and Docker changes use `fix(filesender)` where appropriate.

## Fast-IT charts

`webcomponent`, `webapp`, `svc-postgres`, and `svc-mongodb` remain `0.x`.
Their Release PR is the stability decision. Dependencies are resolved from
the published Helm repository (`>= 0.1.0-0`), while a release gate rejects a
`webapp` lock file containing `-rc` or `-alpha`.

## Renovate and adding artifacts

Renovate targets `main`. GitHub Action updates are `chore(ci)` and may
automerge; package updates are scoped to the affected chart. To add a chart or
image, add an entry to `.github/config/charts.json` or `images.json`, include
its path filter, and add the corresponding package to the release-please
configuration and manifest.

## Maintainer migration checklist

After this migration, close PR #31, configure protected `main` with required
`pr-validation` checks and mandatory pull requests, ensure the workflow token
has `contents: write`, `packages: write`, and `pull-requests: write`, remove
orphaned RCs, and delete `develop`. No workflow pushes to `main`; the only
automated write is to the Helm `gh-pages` branch and GitHub Releases.
