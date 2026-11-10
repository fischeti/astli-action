# astli-action

A GitHub Action that sets up [astli](https://github.com/fischeti/astli), the
SystemVerilog toolchain: it puts the `astli` binary on `PATH`, caches the git
dependencies astli downloads, and has diagnostics annotate the pull request.

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: fischeti/astli-action@v0.5.2
      - run: astli fmt --check
      - run: astli lint --locked
      - run: astli check --locked --top soc_top
```

Each tag installs the astli release of the same version, so the tag picks the
formatter and the lint rules, and Dependabot's `github-actions` updates upgrade
both. Tags follow astli releases within a day.

It runs on Linux (x86_64, aarch64), macOS (x86_64, arm64) and Windows (x86_64).

## Inputs

| Input | Default | Description |
| :--- | :--- | :--- |
| `version` | the tag's | The astli version to install. |
| `cache` | `true` | Whether to cache the git dependencies astli downloads. |
| `cache-dependency-path` | `astli.lock` | The lock file whose hash keys the cache. Nothing is cached when it does not exist. |
| `annotations` | `true` | Whether to set `ASTLI_DIAGNOSTICS=github`, so that each diagnostic annotates the line of the pull request it is about. Needs astli 0.4.0. |

The cache lives in `ASTLI_CACHE_DIR`, which the action sets for the rest of
the job. A run whose lock file changed starts from the newest cache of the same
OS.

## Outputs

| Output | Description |
| :--- | :--- |
| `version` | The astli version installed. |
| `cache-hit` | Whether the cache was restored from an exact key match. |

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.
