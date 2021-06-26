#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test the base module.
]]--

local utils = require "spec.utils"
local kube = require "kube"

describe("Kube module", function()
  describe("should be tested", function()
    it("should return a version", function()
      assert.is.starting_with(kube.version(), "0.1.0")
    end)
  end)
end)
