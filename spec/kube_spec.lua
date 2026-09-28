#!/usr/bin/env lua

local kube = require("kube")

describe("Kube module", function()
  describe("should be tested", function()
    it("should return a version", function()
      assert.equals("0.1.0-0", kube.version())
    end)
  end)
end)
