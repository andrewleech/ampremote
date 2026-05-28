# ampremote

Local integration distribution of MicroPython's `mpremote` tool, packaged as
`ampremote` and installed as the `ampremote` and `ampr` CLI commands.

This repository is an [mbm](https://github.com/andrewleech/micropython-branch-manager)
integration of the upstream `mpremote` source from
[micropython/micropython](https://github.com/micropython/micropython) with a
set of in-flight PRs and local-only patches applied. The branches included
are listed in `mbm.toml`.

## Layout

- `micropython/` - submodule, on the `ampremote` integration branch
- `mbm.toml` - list of PRs and local branches that compose the integration
- `Makefile` - wheel build and editable install targets

## Build and install

```bash
make install    # install ampremote and ampr from the working tree in editable mode (uv tool)
make wheel      # build a wheel under dist/
make uninstall  # remove the uv tool install
```

The editable install means edits under `micropython/tools/mpremote/mpremote/`
take effect immediately without reinstalling.

## Updating the integration

```bash
mbm config       # show current branch set
mbm add-pr <N>   # add an upstream PR to the integration
mbm rebase       # rebuild ampremote on top of latest upstream master
```

Conflict resolutions are recorded via `git rerere` and replay automatically on
rebuild.

## License

MIT, see `LICENSE`. The `mpremote` source under `micropython/tools/mpremote/`
is licensed by its original authors under the MIT license.
