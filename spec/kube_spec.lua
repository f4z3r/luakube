local kube = require "kube"

describe("Kube module", function()
  describe("should be tested", function()
    it("should work", function()
      assert.are.equal("hello", kube.test())
    end)
  end)
end)
