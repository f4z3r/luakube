# LuaKube

![build status](https://github.com/jakobbeckmann/luakube/workflows/test/badge.svg)

Lua abstraction of Kubernetes API.

## Testing

Testing is done with `busted`:

```bash
busted --exclude-tags=system spec
```

To run the system tests:

```bash
busted --defer-print -t system spec
```
