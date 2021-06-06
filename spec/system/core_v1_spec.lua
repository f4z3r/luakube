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

    it("should be able to return all namespaces", function()
      local namespaces = client:namespaces()
      assert.are.equal(5, #namespaces)
    end)

    it("should be able to return a specific namespace", function()
      local ns = client:namespace("demo")
      assert.are.equal("demo", ns:name())
      assert.are.same({}, ns:annotations())
    end)

    it("should be able to return the status of a specific namespace", function()
      local status = client:namespace_status("demo")
      assert.are.equal("Active", status.phase)
    end)

    it("should be able to return a namespace list object", function()
      local nslist = client:namespacelist()
      assert.are.equal("NamespaceList", nslist.kind)
      assert.are.equal("v1", nslist.apiVersion)
    end)

    it("should be able to return a node list object", function()
      local nodelist = client:nodelist()
      assert.are.equal("NodeList", nodelist.kind)
      assert.are.equal("v1", nodelist.apiVersion)
    end)

    it("should be able to return all nodes", function()
      local nodes = client:nodes()
      assert.are.equal(3, #nodes)
    end)

    it("should be able to return all pods in the kube-system namespace", function()
      local pods = client:pods("kube-system")
      assert.are.equal(9, #pods)
    end)
  end)
end)
