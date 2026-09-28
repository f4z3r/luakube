-- Run against a disposable Kubernetes API; see scripts/test-k3s.sh.
local api = require("kube.api")
local config = require("kube.config")
local socket = require("socket")

describe("discovered resources against Kubernetes #system", function()
  local client
  local suffix = os.date("!%Y%m%d%H%M%S") .. tostring(math.floor(socket.gettime() % 1 * 1000000))
  local namespace = "luakube-discovery-" .. suffix
  local group = "luakube-" .. suffix .. ".test.luakube.dev"
  local group_version = group .. "/v1"
  local crd_name = "widgets." .. group

  setup(function()
    local path =
      assert(os.getenv("LUAKUBE_TEST_KUBECONFIG"), "set LUAKUBE_TEST_KUBECONFIG to a disposable cluster's kubeconfig")
    client = api.Client:new(config.from_kube_config(path))
  end)

  teardown(function()
    if client then
      -- Ignore NotFound when a setup assertion prevented creation.
      pcall(function()
        client:resource("apiextensions.k8s.io/v1", "CustomResourceDefinition"):delete(crd_name)
      end)
      pcall(function()
        client:resource("v1", "Namespace"):delete(namespace)
      end)
    end
  end)

  it("discovers and uses core, grouped and custom resources", function()
    local namespaces = client:resource("v1", "Namespace")
    assert.is_false(namespaces.metadata.namespaced)
    local created, err = namespaces:create({ metadata = { name = namespace } })
    assert.is_not_nil(created, err)
    assert.equals(namespace, namespaces:get(namespace).metadata.name)
    assert.equals("Active", namespaces:subresource("status"):get(namespace).status.phase)

    local pvs = client:resource("v1", "PersistentVolume")
    assert.is_false(pvs.metadata.namespaced)
    assert.equals("PersistentVolumeList", pvs:list().kind)
    assert.equals("DeploymentList", client:resource("apps/v1", "Deployment"):namespace(namespace):list().kind)

    local crds = client:resource("apiextensions.k8s.io/v1", "CustomResourceDefinition")
    local crd = {
      metadata = { name = crd_name },
      spec = {
        group = group,
        scope = "Namespaced",
        names = { plural = "widgets", singular = "widget", kind = "Widget" },
        versions = {
          {
            name = "v1",
            served = true,
            storage = true,
            schema = {
              openAPIV3Schema = {
                type = "object",
                properties = {
                  spec = { type = "object", properties = { color = { type = "string" } } },
                },
              },
            },
          },
        },
      },
    }
    assert.is_not_nil(crds:create(crd))

    local widgets
    for _ = 1, 40 do
      local ok, result = pcall(function()
        client:discover(group_version, true)
        return client:resource(group_version, "Widget"):namespace(namespace)
      end)
      if ok then
        widgets = result
        break
      end
      socket.sleep(0.5)
    end
    assert.is_not_nil(widgets, "CRD did not become discoverable")
    local widget, create_error = widgets:create({ metadata = { name = "demo" }, spec = { color = "red" } })
    assert.is_not_nil(widget, create_error)
    assert.equals("red", widgets:get("demo").spec.color)
    local updated = widgets:patch("demo", { spec = { color = "blue" } })
    assert.equals("blue", updated.spec.color)
    assert.equals("blue", widgets:list().items[1].spec.color)
    updated.spec.color = "green"
    assert.equals("green", widgets:replace(updated).spec.color)
    local applied = widgets:patch(
      "demo",
      table.concat({
        "apiVersion: " .. group_version,
        "kind: Widget",
        "metadata:",
        "  name: demo",
        "  namespace: " .. namespace,
        "spec:",
        "  color: purple",
        "",
      }, "\n"),
      { fieldManager = "luakube-integration", force = true },
      "apply"
    )
    assert.equals("purple", applied.spec.color)
    assert.is_not_nil(widgets:delete("demo"))
  end)
end)
