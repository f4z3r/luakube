#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Test networking V1 API methods against the API with a mock client.
]]--

local utils = require "spec.utils"
local config = require "kube.config"
local api = require "kube.api"

describe("Networking V1 ", function()
  describe("with a local config", function()
    local client
    before_each(function()
      local path = "assets/config"
      local conf = config.from_kube_config(path)
      local global_client = api.Client:new(conf, false, true)
      client = global_client:networkingv1()
    end)

    describe("inspecting ingresses", function()
      it("should be able to return all", function()
        local _, info = client:ingresses():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/ingresses")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:ingresses("kube-system"):get("kube-dns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/kube-system/ingresses/kube-dns")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:ingresses("kube-system"):status("kube-dns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/kube-system/ingresses/kube-dns/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:ingresses():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/ingresses")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:ingresses("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/kube-system/ingresses")
      end)

      it("should be able to update one", function()
        local ing_obj = {
          metadata = {
            name = "demo-ing-test",
            namespace = "demo",
          },
          spec = {
            rules = {
              {
                host = "demo.example.com",
                http = {
                  paths = {
                    {
                      path = "/",
                      pathType = "Prefix",
                      backend = {
                        serviceName = "demo-srv",
                        servicePort = 80
                      }
                    }
                  }
                }
              },
            }
          }
        }
        local expected = {
          apiVersion = "networking.k8s.io/v1",
          kind = "Ingress",
          metadata = {
            name = "demo-ing-test",
            namespace = "demo",
          },
          spec = {
            rules = {
              {
                host = "demo.example.com",
                http = {
                  paths = {
                    {
                      path = "/",
                      pathType = "Prefix",
                      backend = {
                        serviceName = "demo-srv",
                        servicePort = 80
                      }
                    }
                  }
                }
              },
            }
          }
        }
        local _, info = client:ingresses("demo"):update(ing_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/demo/ingresses/demo-ing-test")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local ing_obj = {
          metadata = {
            name = "demo-ing-test",
            namespace = "demo",
          },
          spec = {
            rules = {
              {
                host = "demo.example.com",
                http = {
                  paths = {
                    {
                      path = "/",
                      pathType = "Prefix",
                      backend = {
                        serviceName = "demo-srv",
                        servicePort = 80
                      }
                    }
                  }
                }
              },
            }
          }
        }
        local _, info = client:ingresses("demo"):update_status(ing_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/demo/ingresses/demo-ing-test/status")
      end)

      it("should be able to create one", function()
        local ing_obj = {
          metadata = {
            name = "demo-ing-test",
            namespace = "demo",
          },
          spec = {
            rules = {
              {
                host = "demo.example.com",
                http = {
                  paths = {
                    {
                      path = "/",
                      pathType = "Prefix",
                      backend = {
                        serviceName = "demo-srv",
                        servicePort = 80
                      }
                    }
                  }
                }
              },
            }
          }
        }
        local expected = {
          apiVersion = "networking.k8s.io/v1",
          kind = "Ingress",
          metadata = {
            name = "demo-ing-test",
            namespace = "demo",
          },
          spec = {
            rules = {
              {
                host = "demo.example.com",
                http = {
                  paths = {
                    {
                      path = "/",
                      pathType = "Prefix",
                      backend = {
                        serviceName = "demo-srv",
                        servicePort = 80
                      }
                    }
                  }
                }
              },
            }
          }
        }
        local _, info = client:ingresses("demo"):create(ing_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/demo/ingresses")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:ingresses("demo"):delete("ing")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/networking.k8s.io/v1/namespaces/demo/ingresses/ing")
      end)
    end)
  end)
end)

