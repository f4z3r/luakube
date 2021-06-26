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

      it("should be able to return a specific one", function()
        local _, info = client:jobs("kube-system"):get("helm-install-traefik")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/jobs/helm-install-traefik")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:jobs("demo"):status("my-job")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/jobs/my-job/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:jobs():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/jobs")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:jobs("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/jobs")
      end)

      it("should be able to update one", function()
        local jobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
          apiVersion = "batch/v1",
          kind = "Job",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
        local _, info = client:jobs("demo"):update(jobs_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/jobs/my-job")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local jobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
            active = 1
          }
        }
        local expected = {
          apiVersion = "batch/v1",
          kind = "Job",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
            active = 1
          }
        }
        local _, info = client:jobs("demo"):update_status(jobs_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/jobs/my-job/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local jobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
          apiVersion = "batch/v1",
          kind = "Job",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
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
        local _, info = client:jobs("demo"):create(jobs_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/jobs")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:jobs("demo"):delete("my-job")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/jobs/my-job")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:jobs():delete_collection({}, params)
        end)
        local _, info = client:jobs("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/jobs?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)

    describe("inspecting cronjobs", function()
      it("should be able to return all", function()
        local _, info = client:cronjobs():get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/cronjobs")
      end)

      it("should be able to return a specific one", function()
        local _, info = client:cronjobs("kube-system"):get("helm-install-traefik")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/cronjobs/helm-install-traefik")
      end)

      it("should be able to return the status of a specific one", function()
        local _, info = client:cronjobs("demo"):status("my-job")
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/cronjobs/my-job/status")
      end)

      it("should be able to return all in list", function()
        local _, info = client:cronjobs():list()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/cronjobs")
      end)

      it("should be able to return all in the kube-system namespace", function()
        local _, info = client:cronjobs("kube-system"):get()
        assert.are.equal("GET", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/cronjobs")
      end)

      it("should be able to update one", function()
        local cronjobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
        }
        local expected = {
          apiVersion = "batch/v1",
          kind = "CronJob",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
        }
        local _, info = client:cronjobs("demo"):update(cronjobs_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/cronjobs/my-job")
        assert.are.same(expected, info.body)
      end)

      it("should be able to update the status of one", function()
        local cronjobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
          },
          status = {
            active = 1
          }
        }
        local expected = {
          apiVersion = "batch/v1",
          kind = "CronJob",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
          },
          status = {
            active = 1
          }
        }
        local _, info = client:cronjobs("demo"):update_status(cronjobs_obj)
        assert.are.equal("PUT", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/cronjobs/my-job/status")
        assert.are.same(expected, info.body)
      end)

      it("should be able to create one", function()
        local cronjobs_obj = {
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
        }
        local expected = {
          apiVersion = "batch/v1",
          kind = "CronJob",
          metadata = {
            name = "my-job",
            namespace = "demo",
          },
          spec = {
            schedule = "15 */6 * * *",
            jobTemplate = {
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
        }
        local _, info = client:cronjobs("demo"):create(cronjobs_obj)
        assert.are.equal("POST", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/cronjobs")
        assert.are.same(expected, info.body)
      end)

      it("should be able to delete one", function()
        local _, info = client:cronjobs("demo"):delete("my-job")
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/demo/cronjobs/my-job")
      end)

      it("should be able to delete several", function()
        local params = {
          labelSelector = "app=to-delete",
          dryRun = true
        }
        assert.has.errors(function()
          local _, _ = client:cronjobs():delete_collection({}, params)
        end)
        local _, info = client:cronjobs("kube-system"):delete_collection({}, params)
        assert.are.equal("DELETE", info.method)
        assert.is.ending_with(info.url, "/apis/batch/v1/namespaces/kube-system/cronjobs?dryRun=true&labelSelector=app%3Dto-delete")
      end)
    end)
  end)
end)

