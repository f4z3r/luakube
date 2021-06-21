#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test core V1 API methods against the API with a mock client.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Core V1 ", function()
  describe("with a local config", function()
    local client
    before_each(function()
      local path = "assets/config"
      local conf = config.from_kube_config(path)
      local global_client = api.Client:new(conf, true)
      client = global_client:corev1()
    end)

    describe("inspecting namespaces", function()
      it("should not be a namespaced client", function()
        assert.has.errors(function()
          client:namespaces("demo")
        end)
      end)

      it("should be able to return all", function()
        local _, info = client:namespaces():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:namespaces():get("demo")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:namespaces():status("demo")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:namespaces():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces")
      end)

      it("should be able to update one", function()
        local ns = {
          metadata = {
            name = "demo",
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Namespace",
          metadata = {
            name = "demo"
          }
        }
        local _, info = client:namespaces():update(ns)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create/delete one", function()
        local _, info = client:namespaces():delete("demo")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
      end)
    end)
  end)
end)

