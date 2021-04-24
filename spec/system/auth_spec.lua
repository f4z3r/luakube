#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test authentication methods against the API.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api_client = require "kube.api_client"

describe("Authentication #system", function()
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

  describe("with kube config", function()
    local configuration = config.from_kube_config()

    it("return the correct context", function()
      assert.are.same("k3d-"..name , configuration:context())
    end)
  end)
end)
