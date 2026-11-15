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
      - uses: fischeti/astli-action@v0.6.0
      - run: astli fmt --check
      - run: astli lint --locked
      - run: astli check --locked --top soc_top
```

Each tag installs the astli release of the same version, so the tag picks the
formatter and the lint rules, and Dependabot's `github-actions` updates upgrade
both. Tags follow astli releases within a day.

It runs on Linux (x86_64, aarch64), macOS (arm64) and Windows (x86_64).

## Inputs

| Input | Default | Description |
| :--- | :--- | :--- |
| `version` | the tag's | The astli version to install. |
| `cache` | `true` | Whether to cache the git dependencies astli downloads. |
| `cache-dependency-path` | `astli.lock` | The lock file whose hash keys the cache. Nothing is cached when it does not exist. |
| `build-cache` | `false` | Whether to cache builds, so that `astli build`, `run` and `test` skip each top nothing it reads changed in, and recompile only the C++ that changed in the rest. Not on Windows. |
| `build-cache-size` | `500M` | The most the build cache keeps, as `CCACHE_MAXSIZE`, unless that is set. |
| `build-cache-save` | on a push | Whether to save the build cache, rather than only restore it. |
| `build-cache-key` | | What tells apart the build caches of jobs of one name, such as the legs of a matrix. |
| `annotations` | `true` | Whether to set `ASTLI_DIAGNOSTICS=github`, so that each diagnostic annotates the line of the pull request it is about. Needs astli 0.4.0. |

The cache lives in `ASTLI_CACHE_DIR`, which the action sets for the rest of
the job. A run whose lock file changed starts from the newest cache of the same
OS.

### Caching builds

With `build-cache: true`, the action caches two things after every run:

- **Each top's executable and fingerprint** in `.astli/build`. astli skips a
  build whose fingerprint, a hash of every file the top reads, its flags, and
  astli's and Verilator's versions, is unchanged. Under `astli test`, each
  point a change does not reach is skipped outright on a new runner. The rest
  of a build is left out: Verilator rewrites every file it generates, so a
  build that runs recompiles them all whatever is restored.
- **What `ccache` compiled**, which the action installs unless it is on
  `PATH`. astli hands it to Verilator wherever it is on `PATH`, so the tops
  that are built compile from the cache what a change left as it was, and
  Verilator's runtime, the same in every top, compiles once.

Use it after `actions/checkout`, which would delete the restored builds.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: fischeti/astli-action@v0.6.0
        with:
          build-cache: true
      - run: sudo apt-get install -y verilator
      - run: astli test --locked
```

Each push saves a cache of its own, restored by the next run of the same
job, or of any job on the same OS; a pull request only restores, so that its
runs do not crowd out the default branch's. Legs of a matrix share a job's
name, so give each its own `build-cache-key`, such as
`${{ matrix.verilator }}`, or only the first to finish is saved. The
fingerprint does not hold the C++ compiler, so executables are kept apart by
the runner's OS release, such as `ubuntu26`, and a new release builds every
top again.

### Security

A job runs what it restores, so a cache entry written by untrusted code can
run in every job after it. Leave `cache` and `build-cache` off in jobs that
hold secrets or publish, and in `pull_request_target` and `workflow_run`
workflows. The action pins the actions it uses to commits; lock your
workflows with [`gh actions-lock`](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available/)
to pin this one and them too.

## Outputs

| Output | Description |
| :--- | :--- |
| `version` | The astli version installed. |
| `cache-hit` | Whether the cache was restored from an exact key match. |

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.
