#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test core V1 API methods against the API.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Core V1 #system", function()
  io.write("starting system test:\n")
  local tear
  local name
  setup(function()
    io.write("creating test cluster for core v1 system testing...\n")
    name, tear = utils.create_k3d_cluster()
    utils.initialize_deployments()
    utils.sleep(30)
  end)
  teardown(function()
    if tear then
      io.write("deleting test cluster for core v1 system testing...\n")
      tear()
    end
  end)

  describe("with a local config", function()
    local client
    before_each(function()
      local conf = config.from_kube_config()
      local global_client = api.Client:new(conf)
      client = global_client:corev1()
    end)

    describe("inspecting namespaces", function()
      it("should be able to return all", function()
        local namespaces = client:namespaces():get()
        assert.are.equal(5, #namespaces)
      end)

      it("should be able to return a specific one", function()
        local ns = client:namespaces():get("demo")
        assert.are.equal("demo", ns:name())
        assert.are.same({}, ns:annotations())
      end)

      it("should be able to return the status of a specific one", function()
        local status = client:namespaces():status("demo")
        assert.are.equal("Active", status.phase)
      end)

      it("should be able to return all in list", function()
        local nslist = client:namespaces():list()
        assert.are.equal("NamespaceList", nslist.kind)
        assert.are.equal("v1", nslist.apiVersion)
      end)

      it("should be able to create/delete one", function()
        local namespace = {
          metadata = {
            name = "test",
            labels = {
              test = "jbe",
            },
          }
        }
        local ns_client = client:namespaces()
        local resp = ns_client:create(namespace)
        assert.are.equal("test", resp:name())
        local _ = ns_client:delete(resp:name())
      end)
    end)

    describe("inspecting nodes", function()
      it("should be able to return all", function()
        local nodes = client:nodes():get()
        assert.are.equal(3, #nodes)
      end)

      -- it("should be able to return a specific one", function()
      --   local ns = client:namespaces():get("demo")
      --   assert.are.equal("demo", ns:name())
      --   assert.are.same({}, ns:annotations())
      -- end)

      it("should be able to return the status of a specific one", function()
        local node_client = client:nodes()
        local node = node_client:get({labelSelector = "node-role.kubernetes.io/master=true"})[1]
        local status = node_client:status(node:name())
        assert.are.equal("amd64", status.nodeInfo.architecture)
      end)

      it("should be able to return all in list", function()
        local nodelist = client:nodes():list()
        assert.are.equal("NodeList", nodelist.kind)
        assert.are.equal("v1", nodelist.apiVersion)
      end)
    end)

    describe("inspecting pods", function()
      it("should be able to return all", function()
        local pods = client:pods():get()
        assert.are.equal(12, #pods)
      end)

      it("should be able to return a specific one", function()
        local pod_base = client:pods():get({labelSelector = "k8s-app=kube-dns"})[1]
        local pod = client:pods(pod_base:namespace()):get(pod_base:name())
        assert.is.starting_with(pod:name(), "coredns")
        assert.are.equal("kube-dns", pod_base:labels()["k8s-app"])
      end)

      it("should be able to return the status of a specific one", function()
        local pod = client:pods():get({labelSelector = "k8s-app=kube-dns"})[1]
        local status = client:pods(pod:namespace()):status(pod:name())
        assert.are.equal("Running", status.phase)
      end)

      it("should be able to return all in list", function()
        local podlist = client:pods():list()
        assert.are.equal("PodList", podlist.kind)
        assert.are.equal("v1", podlist.apiVersion)
      end)

      it("should be able to return all in the kube-system namespace", function()
        local pods = client:pods("kube-system"):get()
        assert.are.equal(9, #pods)
      end)

      it("should be able to get logs of a pod", function()
        local pod = client:pods():get({labelSelector = "k8s-app=kube-dns"})[1]
        local logs = client:logs(pod:namespace(), pod:name(), {tailLines = 25})
        assert.is.containing(logs, "plugin/reload: Running configuration MD5")
      end)

      it("should be able to delete one", function()
        local pod = client:pods():get({labelSelector = "k8s-app=kube-dns"})[1]
        local _ = client:pods(pod:namespace()):delete(pod:name())
      end)

      it("should be able to create one", function()
        local pod_yaml = [[
metadata:
  name: luakube-test-pod
  labels:
    luakube: forever
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80]]
        local resp = client:pods("demo"):create(pod_yaml)
        assert.is.equal("Pending", resp.status.phase)
      end)
    end)
  end)
end)
