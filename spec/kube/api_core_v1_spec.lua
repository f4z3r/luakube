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
      local global_client = api.Client:new(conf, false, true)
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

      it("should be able to update the status of one", function()
        local ns = {
          metadata = {
            name = "demo",
          },
          status = {
            phase = "Pending",
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Namespace",
          metadata = {
            name = "demo"
          },
          status = {
            phase = "Pending",
          }
        }
        local _, info = client:namespaces():update_status(ns)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to patch one", function()
        local patch = {
          metadata = {
            labels = {
              key1 = "value1",
              key2 = "value2",
            }
          }
        }
        local _, info = client:namespaces():patch("demo", patch)
        assert.are.equal("PATCH", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
        assert.are.same(patch, info.body)
      end)

      it("should be able to patch the status of one", function()
        local patch = {
          status = {
            phase = "Active",
          }
        }
        local _, info = client:namespaces():patch("demo", patch)
        assert.are.equal("PATCH", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
        assert.are.same(patch, info.body)
      end)

      it("should be able to create one", function()
        local namespace = {
          metadata = {
            name = "test",
            labels = {
              test = "jbe",
            },
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Namespace",
          metadata = {
            name = "test",
            labels = {
              test = "jbe",
            },
          }
        }
        local _, info = client:namespaces():create(namespace)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:namespaces():delete("demo")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo")
      end)

      it("should not be able to delete several", function()
        local ns_client = client:namespaces()
        assert.is_nil(ns_client.delete_collection)
      end)
    end)

    describe("inspecting nodes", function()
      it("should not be a namespaced client", function()
        assert.has.errors(function()
          client:nodes("demo")
        end)
      end)

      it("should be able to return all", function()
        local _, info = client:nodes():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes")
      end)

      it("should be able to return one based on labels", function()
        local _, info = client:nodes():get({labelSelector = "node-role.kubernetes.io/master=true"})
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes?labelSelector=node-role.kubernetes.io%2Fmaster%3Dtrue")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:nodes():get("demo")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:nodes():status("demo")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:nodes():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes")
      end)

      it("should be able to update one", function()
        local node = {
          metadata = {
            name = "demo"
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Node",
          metadata = {
            name = "demo"
          }
        }
        local _, info = client:nodes():update(node)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local node = {
          metadata = {
            name = "demo"
          }
        }
        local _, info = client:nodes():update_status(node)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo/status")
      end)

      it("should be able to patch one", function()
        local patch = {
          metadata = {
            labels = {
              key1 = "value1",
              key2 = "value2",
            }
          }
        }
        local _, info = client:nodes():patch("demo", patch)
        assert.are.equal("PATCH", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo")
        assert.are.same(patch, info.body)
        assert.are.equal("application/merge-patch+json", info.headers["Content-Type"])
      end)

      it("should be able to delete one", function()
        local _, info = client:nodes():delete("demo")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes/demo")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "os=ubuntu",
          dryRun = true
        }
        local _, info = client:nodes():delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/nodes?dryRun=true&labelSelector=os%3Dubuntu")
      end)
    end)

    describe("inspecting pods", function()
      it("should be able to return all", function()
        local _, info = client:pods():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/pods")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:pods("demo"):get("my-pod")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/pods/my-pod")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:pods("demo"):status("my-pod")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/pods/my-pod/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:pods():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/pods")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:pods("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods")
      end)

      it("should be able to get logs of a pod", function()
        local _, info = client:pods("kube-system"):logs("coredns", {tailLines = 25})
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods/coredns/log?tailLines=25")
      end)

      it("should be able to update one", function()
        local pod = {
          metadata = {
            name = "demo",
            namespace = "kube-system"
          },
          spec = {
            containers = {
              {
                name = "demo",
                image = "busybox",
              },
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Pod",
          metadata = {
            name = "demo",
            namespace = "kube-system"
          },
          spec = {
            containers = {
              {
                name = "demo",
                image = "busybox",
              },
            }
          }
        }
        local _, info = client:pods("kube-system"):update(pod)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods/demo")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local pod = {
          metadata = {
            name = "demo",
            namespace = "kube-system"
          },
          spec = {
            containers = {
              {
                name = "demo",
                image = "busybox",
              },
            }
          }
        }
        local _, info = client:pods("kube-system"):update_status(pod)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods/demo/status")
      end)

      it("should be able to delete one", function()
        local _, info = client:pods("kube-system"):delete("coredns")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods/coredns")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:pods():delete_collection({}, params)
        end)
        local _, info = client:pods("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/pods?dryRun=true&labelSelector=app%3Dto-delete")
      end)

      it("should be able to create one", function()
        local pod_yaml = [[
metadata:
  name: luakube-test-pod
  labels:
    luakube: forever
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80]]
        local expected = {
          apiVersion = "v1",
          kind = "Pod",
          metadata = {
            name = "luakube-test-pod",
            labels = {
              luakube = "forever",
            },
          },
          spec = {
            containers = {
              {
                name = "nginx",
                image = "nginx:1.14.2",
                ports = {
                  {
                    containerPort = 80
                  },
                }
              },
            }
          }
        }
        local _, info = client:pods("demo"):create(pod_yaml)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/pods")
        assert.are.same(expected, info.body)
      end)
    end)

    describe("inspecting services", function()
      it("should be able to return all", function()
        local _, info = client:services():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/services")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:services("kube-system"):get("kube-dns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/services/kube-dns")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:services("kube-system"):status("kube-dns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/services/kube-dns/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:services():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/services")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:services("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/services")
      end)

      it("should be able to update one", function()
        local svc_obj = {
          metadata = {
            name = "demo-svc-test",
            namespace = "demo",
          },
          spec = {
            type = "ClusterIP",
            ports = {
              {
                port = 443,
                name = "https",
                protocol = "TCP",
              },
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Service",
          metadata = {
            name = "demo-svc-test",
            namespace = "demo",
          },
          spec = {
            type = "ClusterIP",
            ports = {
              {
                port = 443,
                name = "https",
                protocol = "TCP",
              },
            }
          }
        }
        local _, info = client:services("demo"):update(svc_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/services/demo-svc-test")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local svc_obj = {
          metadata = {
            name = "demo-svc-test",
            namespace = "demo",
          },
          spec = {
            type = "ClusterIP",
            ports = {
              {
                port = 443,
                name = "https",
                protocol = "TCP",
              },
            }
          }
        }
        local _, info = client:services("demo"):update_status(svc_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/services/demo-svc-test/status")
      end)

      it("should be able to create one", function()
        local svc_obj = {
          metadata = {
            name = "demo-svc-test",
            namespace = "demo",
          },
          spec = {
            type = "ClusterIP",
            ports = {
              {
                port = 443,
                name = "https",
                protocol = "TCP",
              },
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Service",
          metadata = {
            name = "demo-svc-test",
            namespace = "demo",
          },
          spec = {
            type = "ClusterIP",
            ports = {
              {
                port = 443,
                name = "https",
                protocol = "TCP",
              },
            }
          }
        }
        local _, info = client:services("demo"):create(svc_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/services")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:services("demo"):delete("svc")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/services/svc")
      end)
    end)

    describe("inspecting configmaps", function()
      it("should be able to return all", function()
        local _, info = client:configmaps():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/configmaps")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:configmaps("kube-system"):get("coredns")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/configmaps/coredns")
      end)

      it("should not have a status", function()
        assert.is_nil(client:configmaps("kube-system").status)
        assert.is_nil(client:configmaps("kube-system").update_status)
      end)

      it("should be able to return all in list", function()
        local _, info = client:configmaps():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/configmaps")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:configmaps("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/configmaps")
      end)

      it("should be able to update one", function()
        local cm_obj = {
          metadata = {
            name = "demo-cm-test",
            namespace = "demo",
          },
          data = {
            url = "hello.world",
            username = "whoami",
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "ConfigMap",
          metadata = {
            name = "demo-cm-test",
            namespace = "demo",
          },
          data = {
            url = "hello.world",
            username = "whoami",
          }
        }
        local _, info = client:configmaps("demo"):update(cm_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/configmaps/demo-cm-test")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local cm_obj = {
          metadata = {
            name = "demo-cm-test",
            namespace = "demo",
          },
          data = {
            url = "hello.world",
            username = "whoami",
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "ConfigMap",
          metadata = {
            name = "demo-cm-test",
            namespace = "demo",
          },
          data = {
            url = "hello.world",
            username = "whoami",
          }
        }
        local _, info = client:configmaps("demo"):create(cm_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/configmaps")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:configmaps("demo"):delete("config")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/configmaps/config")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:configmaps():delete_collection({}, params)
        end)
        local _, info = client:configmaps("demo"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/configmaps?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting secrets", function()
      it("should be able to return all", function()
        local _, info = client:secrets():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/secrets")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:secrets("kube-system"):get("k3s-serving")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/secrets/k3s-serving")
      end)

      it("should not have a status", function()
        assert.is_nil(client:secrets("kube-system").status)
        assert.is_nil(client:secrets("kube-system").update_status)
      end)

      it("should be able to return all in list", function()
        local _, info = client:secrets():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/secrets")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:secrets("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/secrets")
      end)

      it("should be able to update one", function()
        local sec_obj = {
          metadata = {
            name = "demo-sec-test",
            namespace = "demo",
          },
          type = "Opaque",
          data = {
            password = "c2VjcmV0"
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Secret",
          metadata = {
            name = "demo-sec-test",
            namespace = "demo",
          },
          type = "Opaque",
          data = {
            password = "c2VjcmV0"
          }
        }
        local _, info = client:secrets("demo"):update(sec_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/secrets/demo-sec-test")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local sec_obj = {
          metadata = {
            name = "demo-sec-test",
            namespace = "demo",
          },
          type = "Opaque",
          data = {
            password = "c2VjcmV0"
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Secret",
          metadata = {
            name = "demo-sec-test",
            namespace = "demo",
          },
          type = "Opaque",
          data = {
            password = "c2VjcmV0"
          }
        }
        local _, info = client:secrets("demo"):create(sec_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/secrets")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:secrets("demo"):delete("sec")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/secrets/sec")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:secrets():delete_collection({}, params)
        end)
        local _, info = client:secrets("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/secrets?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting service accounts", function()
      it("should be able to return all", function()
        local _, info = client:serviceaccounts():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/serviceaccounts")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:serviceaccounts("kube-system"):get("admin")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/serviceaccounts/admin")
      end)

      it("should not have a status", function()
        assert.is_nil(client:serviceaccounts("kube-system").status)
        assert.is_nil(client:serviceaccounts("kube-system").update_status)
      end)

      it("should be able to return all in list", function()
        local _, info = client:serviceaccounts():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/serviceaccounts")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:serviceaccounts("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/serviceaccounts")
      end)

      it("should be able to update one", function()
        local sa_obj = {
          metadata = {
            name = "sa-test",
            namespace = "demo",
          },
          automountServiceAccountToken = true
        }
        local expected = {
          apiVersion = "v1",
          kind = "ServiceAccount",
          metadata = {
            name = "sa-test",
            namespace = "demo",
          },
          automountServiceAccountToken = true
        }
        local _, info = client:serviceaccounts("demo"):update(sa_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/serviceaccounts/sa-test")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local sa_obj = {
          metadata = {
            name = "sa-test",
            namespace = "demo",
          },
          automountServiceAccountToken = true
        }
        local expected = {
          apiVersion = "v1",
          kind = "ServiceAccount",
          metadata = {
            name = "sa-test",
            namespace = "demo",
          },
          automountServiceAccountToken = true
        }
        local _, info = client:serviceaccounts("demo"):create(sa_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/serviceaccounts")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:serviceaccounts("demo"):delete("sa-test")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/serviceaccounts/sa-test")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:serviceaccounts():delete_collection({}, params)
        end)
        local _, info = client:serviceaccounts("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/serviceaccounts?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting endpoints", function()
      it("should be able to return all", function()
        local _, info = client:endpoints():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/endpoints")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:endpoints("kube-system"):get("external-ep")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/endpoints/external-ep")
      end)

      it("should not have a status", function()
        assert.is_nil(client:endpoints("kube-system").status)
        assert.is_nil(client:endpoints("kube-system").update_status)
      end)

      it("should be able to return all in list", function()
        local _, info = client:endpoints():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/endpoints")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:endpoints("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/endpoints")
      end)

      it("should be able to update one", function()
        local ep_obj = {
          metadata = {
            name = "kube-dns",
            namespace = "demo",
          },
          subsets = {
            {
              addresses = {
                {
                  ip = "10.42.1.254",
                }
              },
              ports = {
                {
                  name = "dns-tcp",
                  port = 53,
                  protocol = "TCP"
                }
              }
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Endpoints",
          metadata = {
            name = "kube-dns",
            namespace = "demo",
          },
          subsets = {
            {
              addresses = {
                {
                  ip = "10.42.1.254",
                }
              },
              ports = {
                {
                  name = "dns-tcp",
                  port = 53,
                  protocol = "TCP"
                }
              }
            }
          }
        }
        local _, info = client:endpoints("demo"):update(ep_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/endpoints/kube-dns")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local ep_obj = {
          metadata = {
            name = "kube-dns",
            namespace = "demo",
          },
          subsets = {
            {
              addresses = {
                {
                  ip = "10.42.1.254",
                }
              },
              ports = {
                {
                  name = "dns-tcp",
                  port = 53,
                  protocol = "TCP"
                }
              }
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "Endpoints",
          metadata = {
            name = "kube-dns",
            namespace = "demo",
          },
          subsets = {
            {
              addresses = {
                {
                  ip = "10.42.1.254",
                }
              },
              ports = {
                {
                  name = "dns-tcp",
                  port = 53,
                  protocol = "TCP"
                }
              }
            }
          }
        }
        local _, info = client:endpoints("demo"):create(ep_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/endpoints")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:endpoints("demo"):delete("ep-test")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/endpoints/ep-test")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:endpoints():delete_collection({}, params)
        end)
        local _, info = client:endpoints("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/endpoints?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting pvcs", function()
      it("should be able to return all", function()
        local _, info = client:pvc():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/persistentvolumeclaims")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:pvc("kube-system"):get("persist-vol")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumeclaims/persist-vol")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:pvc("demo"):status("storage")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumeclaims/storage/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:pvc():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/persistentvolumeclaims")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:pvc("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumeclaims")
      end)

      it("should be able to update one", function()
        local pvc_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolumeClaim",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          }
        }
        local _, info = client:pvc("demo"):update(pvc_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumeclaims/storage")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local pvc_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          },
          status = {
            accessModes = {
              "ReadOnly",
              "ReadWrite"
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolumeClaim",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          },
          status = {
            accessModes = {
              "ReadOnly",
              "ReadWrite"
            }
          }
        }
        local _, info = client:pvc("demo"):update_status(pvc_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumeclaims/storage/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local pvc_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolumeClaim",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            storageClassName = "host-path"
          }
        }
        local _, info = client:pvc("demo"):create(pvc_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumeclaims")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:pvc("demo"):delete("storage")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumeclaims/storage")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:pvc():delete_collection({}, params)
        end)
        local _, info = client:pvc("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumeclaims?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting persistentvolumes", function()
      it("should be able to return all", function()
        local _, info = client:pv():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/persistentvolumes")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:pv("kube-system"):get("persist-vol")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumes/persist-vol")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:pv("demo"):status("storage")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumes/storage/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:pv():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/persistentvolumes")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:pv("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumes")
      end)

      it("should be able to update one", function()
        local pv_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolume",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          }
        }
        local _, info = client:pv("demo"):update(pv_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumes/storage")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local pv_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          },
          status = {
            accessModes = {
              "ReadOnly",
              "ReadWrite"
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolume",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          },
          status = {
            accessModes = {
              "ReadOnly",
              "ReadWrite"
            }
          }
        }
        local _, info = client:pv("demo"):update_status(pv_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumes/storage/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local pv_obj = {
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          }
        }
        local expected = {
          apiVersion = "v1",
          kind = "PersistentVolume",
          metadata = {
            name = "storage",
            namespace = "demo",
          },
          spec = {
            capacity = {
              storage = "5Gi"
            }
          }
        }
        local _, info = client:pv("demo"):create(pv_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumes")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:pv("demo"):delete("storage")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/demo/persistentvolumes/storage")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:pv():delete_collection({}, params)
        end)
        local _, info = client:pv("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/api/v1/namespaces/kube-system/persistentvolumes?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)
  end)
end)

