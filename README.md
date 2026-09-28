# luakube

![build status](https://github.com/jakobbeckmann/luakube/workflows/test/badge.svg)

LuaKube is a simple client library to access the Kubernetes API. It does not abstract much from the
API, allowing for full control, but provides some convenience functions for quick scripting.

## Getting Started

Install this checkout with `luarocks make rockspecs/luakube-0.1.0-0.rockspec`,
then use a kubeconfig containing a bearer token or client certificate:

```lua
local config = require "kube.config"
local Client = require "kube.api".Client

local client = Client:new(config.from_kube_config(os.getenv("KUBECONFIG")))
local pods = client:resource("v1", "Pod")
local deployments = client:resource("apps/v1", "Deployment")

local all_pods = pods:list({ labelSelector = "app=my-app" })
local pod = pods:namespace("default"):get("my-app")
local items = deployments:namespace("default"):list().items
```

`resource(group_version, kind_or_resource_name)` loads that group's resource
list once from `/api/v1` or `/apis/GROUP/VERSION`. It resolves a kind, plural
resource name, singular name, or short name from the server's discovery data.
This also works for CRDs once their APIs become available. Use
`client:discover("example.com/v1", true)` to refresh a group after creating a
CRD or changing available API versions.

## Documentation

The generic resource client supports `get(name, query)`, `list(query)`,
`create(object, query)`, `replace(object, query)` (also `update`),
`patch(name, patch, query, style)`, `delete(name, query, body)`, and
`delete_collection(body, query)` where advertised by discovery. Namespace
scoping is explicit for writes and named reads; listing a namespaced resource
without `:namespace(...)` lists across namespaces. The resource object's
`metadata` contains its discovered `name`, `kind`, `namespaced`, `verbs`, and
`subresources`.

```lua
local configmaps = client:resource("v1", "ConfigMap"):namespace("default")
local created, info, code = configmaps:create({
  metadata = { name = "my-config" }, data = { key = "value" }
})
local updated = configmaps:patch("my-config", { data = { key = "other" } })
local status = configmaps:delete("my-config")

-- Generic subresources use the same name and namespace path construction:
local logs = pods:namespace("default"):subresource("log")
  :get_raw("my-app", { tailLines = 50 })
local pod_status = pods:namespace("default"):subresource("status"):get("my-app")
```

Create and replace add missing `apiVersion`, `kind`, and (when scoped)
`metadata.namespace` without changing the supplied table. API responses are
plain decoded Lua tables. On HTTP errors, methods return `nil, message, code`;
passing `{ panic = true }` as the second argument to `Client:new` raises
instead. Patch styles are `merge` (default), `json`, `strategic`, and `apply`;
server-side apply requires a `fieldManager` query parameter. `get_raw` returns
the response body as a string for endpoints such as pod logs. For unusual
subresource actions, use `:subresource("eviction"):request("POST", pod_name, body)`.

Use `client:resource("v1", "Pod")` or `client:resource("batch/v1", "Job")`
for any discovered resource. The former group-specific clients have been removed.

Current scope: this refactor does not change the existing credential or TLS
configuration. In particular, the existing transport disables server
certificate verification. Do not use it for sensitive credentials until that
configuration is fixed. Watches and WebSocket-based operations remain outside
the generic CRUD client.

## Roadmap

The runtime derives ordinary resource paths and operations from the server's
discovery API. Remaining work includes TLS verification and credential handling,
streaming watches, and WebSocket-based exec, attach, and port-forward.

## Contributing

### Testing

#### Unit Tests

> To install `busted`, run `luarocks install busted`.

Testing is done with `busted`:

```bash
busted --exclude-tags=system --lua=$(which lua) spec
```

#### System Tests

For the generic client, `scripts/test-k3s.sh` starts a disposable, agentless
k3s API with embedded etcd, tests core and grouped resources plus a new CRD,
and stops the server. It requires `k3s` and `busted` on the path; set
`K3S_BINARY=/path/to/k3s` if needed. Run it from the repository root:

```bash
scripts/test-k3s.sh
```

To test an existing **disposable** Kubernetes API instead, set
`LUAKUBE_TEST_KUBECONFIG` to its kubeconfig and run
`busted spec/system/discovery_spec.lua`. The test creates a namespace and CRD
and removes them afterward.
