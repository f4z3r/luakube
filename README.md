# LuaKube

![build status](https://github.com/jakobbeckmann/luakube/workflows/test/badge.svg)

LuaKube is a simple client library to access the Kubernetes API. It does not abstract much from the
API, allowing for full control, but provides some convenience functions for quick scripting.

## Testing

Testing is done with `busted`:

```bash
busted --exclude-tags=system spec
```

### System Tests

The system tests require `k3d` to be installed, and the `docker` service to be running.

To run the system tests:

```bash
busted --defer-print -t system spec
# or combined with unit tests
busted --defer-print spec
```
