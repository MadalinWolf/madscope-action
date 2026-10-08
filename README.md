# MadScope action

> Automated responsive website testing and visual regression for GitHub Actions — powered by [MadScope](https://github.com/MadalinWolf/MadScope).

The action renders your URL in real Chromium at multiple viewport sizes, captures screenshots, and — in `test` mode — diffs them against committed baselines, failing the workflow when the visual change exceeds your threshold.

## Usage

```yaml
name: Visual regression

on:
  pull_request:

jobs:
  madscope:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start your site
        run: npm run dev &
        # wait until http://localhost:3000 answers (e.g. wait-on)

      - name: Run MadScope
        id: madscope
        uses: MadalinWolf/madscope-action@v1
        with:
          url: http://localhost:3000
          command: test
          viewports: mobile tablet desktop

      - name: Upload screenshots and diffs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: madscope
          path: |
            .madscope/screenshots/
            .madscope/results/
            madscope-report.json
```

First run: use `command: baseline` (or run `madscope baseline` locally) and commit the `.madscope/baselines/` manifest so `test` has something to compare against.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `url` | yes | — | URL to test (`https://…` or `http://localhost:…` served by a previous step). |
| `command` | no | `test` | `screenshot`, `baseline`, or `test` (the real `madscope` CLI commands). |
| `viewports` | no | `mobile tablet desktop` | Space-separated MadScope viewport preset ids. |
| `threshold` | no | config default | Max fraction (0–1) of changed pixels before failure. |
| `full-page` | no | `false` | `"true"` for full-page screenshots. |
| `working-directory` | no | workspace root | Directory to run in (baselines and `.madscope/` output live here). |

A `madscope.config.ts` in the working directory is honored automatically.

## Testing localhost services

This action runs in a Docker container with its own loopback interface, so a server on the runner is **not** reachable at `127.0.0.1` from inside the action. Serve the site from a service container on the job network and address it by service hostname:

```yaml
jobs:
  madscope:
    runs-on: ubuntu-latest
    services:
      site:
        image: nginx:alpine
        volumes:
          - ${{ github.workspace }}/public:/usr/share/nginx/html:ro
    steps:
      - uses: actions/checkout@v4
      - uses: MadalinWolf/madscope-action@v1
        with:
          url: http://site/
```

For app servers (Node, Python, …), wrap them in a service container or publish them behind a reverse-proxy service on the job network.

## Outputs

| Output | Description |
|---|---|
| `passed` | `true` when the run passed. |
| `max_change_ratio` | Largest changed-pixel fraction across viewports (`test` only). |
| `report` | Workspace-relative path of the JSON report (`test` only). |

## Failure behavior

- `test` exits non-zero (failing your job) when any viewport exceeds the threshold, errors, or has no baseline.
- `screenshot`/`baseline` exit non-zero only on real errors (bad URL, unreachable site).

## Versioning

- `MadalinWolf/madscope-action@v1` — stable major tag, moved forward on compatible updates.
- `MadalinWolf/madscope-action@v1.0.0` — exact release.
- The image bakes a pinned MadScope engine (`MADSCOPE_REF`); engine upgrades ship as new action releases.

## Links

- Engine source: https://github.com/MadalinWolf/MadScope
- Project page: https://madwolfstudios.com/projects/madscope/
- License: MIT
