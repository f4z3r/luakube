# LuaKube

![build status](https://github.com/jakobbeckmann/luakube/workflows/test/badge.svg)

LuaKube is a simple client library to access the Kubernetes API. It does not abstract much from the
API, allowing for full control, but provides some convenience functions for quick scripting.

## Testing

> To install `busted`, run `luarocks install busted`.

Testing is done with `busted`:

```bash
busted --exclude-tags=system --lua=$(which lua) spec
```

### System Tests

The system tests require `k3d` to be installed, and the `docker` service to be running.

To run the system tests:

```bash
busted --defer-print --lua=$(which lua) -t system spec
# or combined with unit tests
busted --defer-print --lua=$(which lua) spec
```

> The `--lua` flag is required when running shims with several lua installations other than the
> system installation.
