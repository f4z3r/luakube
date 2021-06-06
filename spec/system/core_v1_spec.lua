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
        local namespaces = client:namespaces()
        assert.are.equal(5, #namespaces)
      end)

      it("should be able to return a specific one", function()
        local ns = client:namespace("demo")
        assert.are.equal("demo", ns:name())
        assert.are.same({}, ns:annotations())
      end)

      it("should be able to return the status of a specific one", function()
        local status = client:namespace_status("demo")
        assert.are.equal("Active", status.phase)
      end)

      it("should be able to return all in list", function()
        local nslist = client:namespacelist()
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
        local resp = client:create_namespace(namespace)
        assert.are.equal("test", resp:name())
        local status = client:delete_namespace(resp:name())
      end)
    end)

    describe("inspecting nodes", function()
      it("should be able to return all", function()
        local nodes = client:nodes()
        assert.are.equal(3, #nodes)
      end)

      it("should be able to return a specific one", function()
        local ns = client:namespace("demo")
        assert.are.equal("demo", ns:name())
        assert.are.same({}, ns:annotations())
      end)

      it("should be able to return the status of a specific one", function()
        local node = client:nodes({labelSelector = "node-role.kubernetes.io/master=true"})[1]
        local status = client:node_status(node:name())
        assert.are.equal("amd64", status.nodeInfo.architecture)
      end)

      it("should be able to return all in list", function()
        local nodelist = client:nodelist()
        assert.are.equal("NodeList", nodelist.kind)
        assert.are.equal("v1", nodelist.apiVersion)
      end)
    end)

    describe("inspecting pods", function()
      it("should be able to return all", function()
        local pods = client:pods()
        assert.are.equal(12, #pods)
      end)

      it("should be able to return a specific one", function()
        local pod_base = client:pods({labelSelector = "k8s-app=kube-dns"})[1]
        local pod = client:pod(pod_base:namespace(), pod_base:name())
        assert.is.starting_with(pod:name(), "coredns")
        assert.are.equal("kube-dns", pod_base:labels()["k8s-app"])
      end)

      it("should be able to return the status of a specific one", function()
        local pod = client:pods({labelSelector = "k8s-app=kube-dns"})[1]
        local status = client:pod_status(pod:namespace(), pod:name())
        assert.are.equal("Running", status.phase)
      end)

      it("should be able to return all in list", function()
        local podlist = client:podlist()
        assert.are.equal("PodList", podlist.kind)
        assert.are.equal("v1", podlist.apiVersion)
      end)

      it("should be able to return all in the kube-system namespace", function()
        local pods = client:pods("kube-system")
        assert.are.equal(9, #pods)
      end)

      it("should be able to get logs of a pod", function()
        local pod = client:pods({labelSelector = "k8s-app=kube-dns"})[1]
        local logs = client:logs(pod:namespace(), pod:name(), {tailLines = 25})
        assert.is.containing(logs, "plugin/reload: Running configuration MD5")
      end)

      it("should be able to delete one", function()
        local pod = client:pods({labelSelector = "k8s-app=kube-dns"})[1]
        local _ = client:delete_pod(pod:namespace(), pod:name())
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
        local resp = client:create_pod("demo", pod_yaml)
        assert.is.equal("Pending", resp.status.phase)
      end)
    end)
  end)
end)
