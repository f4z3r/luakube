#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Apps V1 API specification.
]]--

local utils = require "kube.api.utils"

local apps_v1 = {}

apps_v1.Client = {}

apps_v1.version_string = "apps/v1"

apps_v1.Client.new = utils.generate_base(apps_v1.version_string)

-- Deployments
local deployment_base = {
  apiVersion = apps_v1.version_string,
  kind = "Deployment",
}
local deploy_extras = {
  scale = function(self, name, replicas, query)
    local patch = {
      spec = {
        replicas = replicas
      }
    }
    return self:patch(name, patch, query)
  end
}
apps_v1.Client.deployments = utils.generate_object_client("deployments", deployment_base, true, true, true, deploy_extras)
apps_v1.Client.deploy = apps_v1.Client.deployments

-- Statefulsets
local statefulset_base = {
  apiVersion = apps_v1.version_string,
  kind = "StatefulSet",
}
local sts_extras = {
  scale = function(self, name, replicas, query)
    local patch = {
      spec = {
        replicas = replicas
      }
    }
    return self:patch(name, patch, query)
  end
}
apps_v1.Client.statefulsets = utils.generate_object_client("statefulsets", statefulset_base, true, true, true, sts_extras)
apps_v1.Client.sts = apps_v1.Client.statefulsets

-- DaemonSets
local daemonset_base = {
  apiVersion = apps_v1.version_string,
  kind = "DaemonSet",
}
local ds_extras = {
  scale = function(self, name, replicas, query)
    local patch = {
      spec = {
        replicas = replicas
      }
    }
    return self:patch(name, patch, query)
  end
}
apps_v1.Client.daemonsets = utils.generate_object_client("daemonsets", daemonset_base, true, true, true, ds_extras)
apps_v1.Client.ds = apps_v1.Client.daemonsets


return apps_v1
