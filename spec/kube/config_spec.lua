--[[
Test suite for the Kubernetes configuration.
]]--

local config = require "kube.config"

describe("The Kubernetes configuration", function()

  describe("given a local configuration", function()

    describe("which is empty", function()

      it("should fail to build configuration", function()
        local path = "assets/empty-config"
        assert.has.errors(function() config.from_kube_config(path) end)
      end)
    end)


    describe("which is non-empty", function()
      local conf
      before_each(function()
        local path = "assets/config"
        conf = config.from_kube_config(path)
      end)

      it("should return all three contexts", function()
        local expected = {
          "k3d-demo",
          "k3d-luakube-121041",
          "k3d-production",
        }
        assert.are.same(expected, conf:contexts())
      end)

      it("should return all three clusters", function()
        local expected = {
          "k3d-demo",
          "k3d-luakube-121041",
          "k3d-production",
        }
        assert.are.same(expected, conf:clusters())
      end)

      it("should return all four users", function()
        local expected = {
          "admin@k3d-demo",
          "admin@k3d-luakube-121041",
          "admin@k3d-production",
          "jbe-staging",
        }
        assert.are.same(expected, conf:usernames())
      end)

      it("should find the current user", function()
        assert.are.equal("admin@k3d-production", conf:username())
      end)

      it("should find the current cluster", function()
        assert.are.equal("k3d-production", conf:cluster())
      end)

      it("should find the correct address", function()
        assert.are.equal("https://0.0.0.0:41101", conf:server_addr())
      end)
    end)


    describe("which is non-empty and initialized with a context", function()
      local conf
      before_each(function()
        local path = "assets/config"
        conf = config.from_kube_config(path, "k3d-demo")
      end)

      it("should find the current user", function()
        assert.are.equal("admin@k3d-demo", conf:username())
      end)

      it("should find the current cluster", function()
        assert.are.equal("k3d-demo", conf:cluster())
      end)

      it("should find the correct address", function()
        assert.are.equal("https://0.0.0.0:46105", conf:server_addr())
      end)

      it("changing the context should provide other address", function()
        conf:context("k3d-production")
        assert.are.equal("https://0.0.0.0:41101", conf:server_addr())
      end)
    end)

  end)
end)
