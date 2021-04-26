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
  end)
  teardown(function()
    if tear then
      io.write("deleting test cluster for core v1 system testing...\n")
      tear()
    end
  end)

  describe("with kube a local config", function()
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
      assert.are.same({}, ns:labels())
      assert.are.same({}, ns:annotations())
    end)

    it("should be able to return a namespace list object", function()
      local nslist = client:namespacelist()
      assert.are.equal("NamespaceList", nslist.kind)
      assert.are.equal("v1", nslist.apiVersion)
    end)
  end)
end)
