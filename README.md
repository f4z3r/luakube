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

> Careful, these test take a decent time to complete, as they create several testing clusters.

```bash
busted --defer-print --lua=$(which lua) -t system spec
# or combined with unit tests
busted --defer-print --lua=$(which lua) spec
```

> The `--lua` flag is required when running shims with several lua installations other than the
> system installation.

## Development

This is used to track the progress of the development. It should show the current state of the
library, including what is supported and what not.

### Progress

- [x] Accept both strings and tables for objects
- [ ] System Tests (covering entire implemented API)
- [ ] Authentication
  - [x] Service Account Token
  - [x] Bootstrap Token
  - [x] Static Token
  - [ ] X509 Certificate
  - [ ] OIDC
  - [ ] Proxy
- [ ] CoreV1
  - [ ] Pods
    - [x] Get
    - [x] Get Status
    - [x] Update
    - [x] Update Status
    - [ ] Patch
    - [x] Create
    - [x] Delete
    - [ ] Delete Collection
    - [x] Logs
    - [ ] EphemeralContainers
    - [ ] Exec
  - [ ] Namespaces
    - [x] Get
    - [x] Get Status
    - [x] Update Status
    - [x] Update
    - [ ] Update Finalizer
    - [ ] Patch
    - [x] Create
    - [x] Delete
  - [ ] Nodes
    - [x] Get
    - [x] Get Status
    - [x] Update Status
    - [x] Update
    - [ ] Patch
    - [x] Create
    - [x] Delete
  - [ ] Services
    - [x] Get
    - [x] Get Status
    - [x] Update
    - [x] Update Status
    - [ ] Patch
    - [x] Create
    - [x] Delete
  - [ ] PodTemplates
    - [x] Get
    - [x] Update
    - [ ] Patch
    - [x] Create
    - [x] Delete
  - [ ] ConfigMap
    - [x] Get
    - [x] Update
    - [ ] Patch
    - [x] Create
    - [x] Delete
  - [ ] Secret
    - [x] Get
    - [x] Update
    - [ ] Patch
    - [x] Create
    - [x] Delete
- [ ] ...
