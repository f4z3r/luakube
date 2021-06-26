#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test apps V1 API methods against the API with a mock client.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Apps V1 ", function()
  describe("with a local config", function()
    local client
    before_each(function()
      local path = "assets/config"
      local conf = config.from_kube_config(path)
      local global_client = api.Client:new(conf, false, true)
      client = global_client:appsv1()
    end)

    describe("inspecting deployments", function()
      it("should be able to return all", function()
        local _, info = client:deployments():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/deployments")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:deployments("kube-system"):get("coredns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/kube-system/deployments/coredns")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:deployments("demo"):status("coredns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/demo/deployments/coredns/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:deployments():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/deployments")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:deployments("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/kube-system/deployments")
      end)

      it("should be able to scale one", function()
        local _, info = client:deployments("kube-system"):scale("coredns", 3)
        local expected = {
          spec = {
            replicas = 3
          }
        }
        assert.are.equal("PATCH", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/kube-system/deployments/coredns")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update one", function()
        local deployments_obj = {
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          }
        }
        local expected = {
          apiVersion = "apps/v1",
          kind = "Deployment",
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          }
        }
        local _, info = client:deployments("demo"):update(deployments_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/demo/deployments/coredns")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local deployments_obj = {
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          },
          status = {
            replicas = 1
          }
        }
        local expected = {
          apiVersion = "apps/v1",
          kind = "Deployment",
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          },
          status = {
            replicas = 1
          }
        }
        local _, info = client:deployments("demo"):update_status(deployments_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/demo/deployments/coredns/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local deployments_obj = {
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          }
        }
        local expected = {
          apiVersion = "apps/v1",
          kind = "Deployment",
          metadata = {
            name = "coredns",
            namespace = "demo",
          },
          spec = {
            selector = {
              matchLabels = {
                ["my-label"] = "label"
              }
            },
            template = {
              metadata = {
                name = "pod-name"
              },
              spec = {
                containers = {
                  {
                    name = "container-name",
                    image = "busybox"
                  }
                }
              }
            }
          }
        }
        local _, info = client:deployments("demo"):create(deployments_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/demo/deployments")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:deployments("demo"):delete("coredns")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/demo/deployments/coredns")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:deployments():delete_collection({}, params)
        end)
        local _, info = client:deployments("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/apps/v1/namespaces/kube-system/deployments?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)
  end)
end)


