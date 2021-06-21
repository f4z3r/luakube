#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test batch V1 API methods against the API with a mock client.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Batch V1 ", function()
  describe("with a local config", function()
    local client
    before_each(function()
      local path = "assets/config"
      local conf = config.from_kube_config(path)
      local global_client = api.Client:new(conf, false, true)
      client = global_client:batchv1()
    end)

    describe("inspecting jobs", function()
      it("should be able to return all", function()
        local _, info = client:jobs():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/jobs")
      end)
    end)
  end)
end)

