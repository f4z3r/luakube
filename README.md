# luakube

![build status](https://github.com/jakobbeckmann/luakube/workflows/test/badge.svg)

LuaKube is a simple client library to access the Kubernetes API. It does not abstract much from the
API, allowing for full control, but provides some convenience functions for quick scripting.

## Getting Started

TODO(@jakob): write this

## Documentation

TODO(@jakob): write this

## Roadmap

The roadmap of the project is documented as [GitHub
projects](https://github.com/f4z3r/luakube/projects).

## Contributing

### Testing

#### Unit Tests

> To install `busted`, run `luarocks install busted`.

Testing is done with `busted`:

```bash
busted --exclude-tags=system --lua=$(which lua) spec
```

#### System Tests

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

### Development

This is used to track the progress of the development. It should show the current state of the
library, including what is supported and what not.

#### Progress

- [x] Accept both strings and tables for objects
- [ ] Define examples and run them as tests with `#example` tag.
- [ ] System Tests (covering entire implemented API)
- [ ] Authentication
  - [x] Service Account Token
  - [x] Bootstrap Token
  - [x] Static Token
  - [ ] X509 Certificate
  - [x] Webhook Token
  - [ ] OIDC
  - [ ] Proxy
- [ ] CoreV1
  - [ ] Pods
    - [x] Get
    - [x] Get Status
    - [x] Update
    - [x] Update Status
    - [x] Patch
    - [x] Create
    - [x] Delete
    - [x] Delete Collection
    - [x] Logs
    - [x] EphemeralContainers
    - [ ] Exec
  - [x] Namespaces
  - [x] Nodes
  - [x] Services
  - [x] PodTemplates
  - [x] ConfigMap
  - [x] Secret
  - [x] ServiceAccounts
  - [x] Endpoints
  - [x] PersistentVolumeClaims
  - [x] PersistentVolumes
  - [x] ReplicationController
  - [x] LimitRange
  - [x] ResourceQuota
  - [ ] Binding (not meant to be used by end user)
  - [ ] ComponentStatus (deprecated)
- [ ] BatchV1
  - [ ] Jobs
    - [x] Get
    - [x] Get Status
    - [x] Update Status
    - [x] Update
    - [x] Patch
    - [x] Create
    - [x] Delete
    - [x] Delete Collection
    - [ ] Watch Streams
  - [ ] CronJobs
