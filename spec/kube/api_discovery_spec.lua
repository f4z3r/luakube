local api = require("kube.api")
local json = require("dkjson")
local ltn12 = require("ltn12")

local core = {
  groupVersion = "v1",
  resources = {
    { name = "pods/log", kind = "Pod", namespaced = true, verbs = { "get" } },
    { name = "pods/status", kind = "Pod", namespaced = true, verbs = { "get", "update", "patch" } },
    { name = "pods/eviction", kind = "Eviction", namespaced = true, verbs = { "create" } },
    {
      name = "pods",
      kind = "Pod",
      singularName = "pod",
      shortNames = { "po" },
      namespaced = true,
      verbs = { "get", "list", "create", "update", "patch", "delete", "deletecollection" },
    },
    {
      name = "persistentvolumes",
      kind = "PersistentVolume",
      namespaced = false,
      verbs = { "get", "list", "create", "update", "patch", "delete" },
    },
  },
}

local apps = {
  groupVersion = "apps/v1",
  resources = {
    {
      name = "deployments",
      kind = "Deployment",
      namespaced = true,
      verbs = { "get", "list", "create", "update", "patch", "delete" },
    },
  },
}

local custom = {
  groupVersion = "example.dev/v1",
  resources = {
    {
      name = "widgets",
      kind = "Widget",
      namespaced = true,
      verbs = { "get", "list", "create", "update", "patch", "delete" },
    },
  },
}

local function fake_client()
  local calls = {}
  local responses = {
    ["/api/v1"] = json.encode(core),
    ["/apis/apps/v1"] = json.encode(apps),
    ["/apis/example.dev/v1"] = json.encode(custom),
  }
  local transport = {
    request = function(params)
      local body = {}
      if params.source then
        local sink = ltn12.sink.table(body)
        ltn12.pump.all(params.source, sink)
      end
      calls[#calls + 1] =
        { url = params.url, method = params.method, headers = params.headers, body = table.concat(body) }
      local path = params.url:match("https://kube.test(.*)")
      local response = responses[path]
      if not response then
        if path:find("/log", 1, true) then
          response = "log line\n"
        elseif path:find("missing", 1, true) then
          ltn12.pump.all(ltn12.source.string('{"kind":"Status","reason":"NotFound"}'), params.sink)
          return true, 404, {}
        else
          response = json.encode({ kind = "Pod", metadata = { name = "demo" }, items = {} })
        end
      end
      ltn12.pump.all(ltn12.source.string(response), params.sink)
      return true, 200, {}
    end,
  }
  local conf = {
    server_addr = function()
      return "https://kube.test/"
    end,
    headers = function()
      return {}
    end,
    cert = function()
      return nil
    end,
    key = function()
      return nil
    end,
  }
  return api.Client:new(conf, { transport = transport }), calls
end

describe("discovery-based API client", function()
  it("discovers and caches each group/version, and resolves CRDs and aliases", function()
    local client, calls = fake_client()
    assert.equals("pods", client:resource("v1", "Pod").metadata.name)
    assert.equals("pods", client:resource("v1", "po").metadata.name)
    assert.equals("widgets", client:resource("example.dev/v1", "Widget").metadata.name)
    assert.equals(2, #calls)
    assert.equals("https://kube.test/api/v1", calls[1].url)
    assert.equals("https://kube.test/apis/example.dev/v1", calls[2].url)
    assert.equals("Pod", client:discover("v1", true)[1].kind)
    assert.equals(3, #calls)
    assert.has_error(function()
      client:resource("v1", "Unknown")
    end)
    assert.has_error(function()
      client:resource("apps/v1/../../api", "Deployment")
    end)
  end)

  it("uses independent group paths and discovered namespace scope", function()
    local client, calls = fake_client()
    local pods = client:resource("v1", "pods")
    local deployments = client:resource("apps/v1", "Deployment")
    pods:namespace("my-ns"):get("a/b", { labelSelector = "app=one two", limit = 0 })
    assert.equals(
      "https://kube.test/api/v1/namespaces/my-ns/pods/a%2Fb?labelSelector=app%3Done%20two&limit=0",
      calls[#calls].url
    )
    deployments:namespace("my-ns"):list()
    assert.equals("https://kube.test/apis/apps/v1/namespaces/my-ns/deployments", calls[#calls].url)
    pods:list()
    assert.equals("https://kube.test/api/v1/pods", calls[#calls].url)
    local pvs = client:resource("v1", "PersistentVolume")
    pvs:get("pv-1")
    assert.equals("https://kube.test/api/v1/persistentvolumes/pv-1", calls[#calls].url)
    assert.has_error(function()
      pvs:namespace("my-ns")
    end)
    assert.has_error(function()
      pods:get("demo")
    end)
    assert.has_error(function()
      pods:delete_collection()
    end)
  end)

  it("supports create, replace, patch, and delete without changing the input", function()
    local client, calls = fake_client()
    local pods = client:resource("v1", "Pod"):namespace("demo")
    local obj = { metadata = { name = "demo" }, spec = { containers = {} } }
    pods:create(obj)
    assert.equals("POST", calls[#calls].method)
    assert.equals("v1", json.decode(calls[#calls].body).apiVersion)
    assert.equals("demo", json.decode(calls[#calls].body).metadata.namespace)
    assert.is_nil(obj.apiVersion)
    assert.is_nil(obj.metadata.namespace)
    pods:replace(obj)
    assert.equals("PUT", calls[#calls].method)
    assert.equals("https://kube.test/api/v1/namespaces/demo/pods/demo", calls[#calls].url)
    pods:patch("demo", { metadata = { labels = { test = "yes" } } })
    assert.equals("application/merge-patch+json", calls[#calls].headers["Content-Type"])
    pods:patch("demo", { { op = "remove", path = "/metadata/labels/test" } }, nil, "json")
    assert.equals("application/json-patch+json", calls[#calls].headers["Content-Type"])
    pods:patch("demo", "apiVersion: v1\nkind: Pod\n", { fieldManager = "luakube" }, "apply")
    assert.equals("application/apply-patch+yaml", calls[#calls].headers["Content-Type"])
    assert.equals("apiVersion: v1\nkind: Pod\n", calls[#calls].body)
    pods:delete("demo", nil, { gracePeriodSeconds = 0 })
    assert.equals("DELETE", calls[#calls].method)
    assert.equals(0, json.decode(calls[#calls].body).gracePeriodSeconds)
    pods:delete_collection(nil, { labelSelector = "test=yes" })
    assert.equals("https://kube.test/api/v1/namespaces/demo/pods?labelSelector=test%3Dyes", calls[#calls].url)
    assert.has_error(function()
      pods:create({ metadata = { namespace = "other" } })
    end)
  end)

  it("routes subresources and handles raw responses and API errors", function()
    local client, calls = fake_client()
    local pods = client:resource("v1", "Pod"):namespace("demo")
    local logs = pods:subresource("log"):get_raw("demo", { tailLines = 5 })
    assert.equals("log line\n", logs)
    assert.equals("https://kube.test/api/v1/namespaces/demo/pods/demo/log?tailLines=5", calls[#calls].url)
    pods:subresource("status"):patch("demo", { status = {} })
    assert.equals("https://kube.test/api/v1/namespaces/demo/pods/demo/status", calls[#calls].url)
    pods:subresource("eviction"):request("POST", "demo", { apiVersion = "policy/v1", kind = "Eviction" })
    assert.equals("https://kube.test/api/v1/namespaces/demo/pods/demo/eviction", calls[#calls].url)
    assert.has_error(function()
      pods:subresource("unknown")
    end)
    assert.has_error(function()
      pods:subresource("log"):patch("demo", {})
    end)
    local missing, err, code = pods:get("missing")
    assert.is_nil(missing)
    assert.equals(404, code)
    assert.matches("NotFound", err)
  end)
end)
