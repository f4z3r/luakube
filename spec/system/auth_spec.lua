#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test authentication methods against the API.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Authentication #system", function()
  io.write("starting system test:\n")
  local tear
  local name
  setup(function()
    io.write("creating test cluster for auth system testing...\n")
    name, tear = utils.create_k3d_cluster()
  end)
  teardown(function()
    if tear then
      io.write("deleting test cluster for auth system testing...\n")
      tear()
    end
  end)

  describe("with kube a local config", function()
    local conf
    before_each(function() conf = config.from_kube_config() end)

    it("should return the correct context", function()
      assert.are.same("k3d-"..name , conf:context())
    end)

    it("should return the correct username", function()
      assert.are.same("admin@k3d-"..name , conf:username())
    end)

    it("should return the correct cluster", function()
      assert.are.same("k3d-"..name , conf:cluster())
    end)

    describe("and with a API client", function()
      local client = api.Client:new(conf)

      it("should be able to get the node list", function()
        local nodes = client:call("GET", "v1/nodes")
        assert.are.equal("NodeList", nodes.kind)
        assert.are.equal(1, #nodes.items)
      end)
    end)
  end)
end)
