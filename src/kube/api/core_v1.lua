#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Core V1 API specification.
]]--

local yaml = require "lyaml"

local utils = require "kube.api.utils"
local objects = require "kube.api.objects"

local core_v1 = {}

core_v1.Client = {}

core_v1.version_string = "v1"

core_v1.Client.new = utils.generate_base(core_v1.version_string)

-- Nodes
local node_base = {
  apiVersion = core_v1.version_string,
  kind = "Node",
}
core_v1.Client.nodes = utils.generate_object_client("nodes", node_base, false)

-- Namespaces
local ns_base = {
  apiVersion = core_v1.version_string,
  kind = "Namespace",
}
local extras = {
  finalize = function(self, obj, query)
    if type(obj) == "string" then
      obj = yaml.load(obj)
    end
    for key, val in pairs(ns_base) do
      obj[key] = val
    end
    local path = string.format("/%s/finalize", obj.metadata.name)
    local resp, info, code = self:call("PUT", path, obj, query)
    return objects.APIObject:new(resp), info, code
  end
}
core_v1.Client.namespaces = utils.generate_object_client("namespaces", ns_base, false, true, false, extras)
core_v1.Client.ns = core_v1.Client.namespaces

-- Pods
local pod_base = {
  apiVersion = core_v1.version_string,
  kind = "Pod",
}
local extras = {
  logs = function(self, name, query)
    assert(self.namespaced_, "can only pod logs when providing namespace")
    local path = string.format("/%s/log", name)
    return self:raw_call("GET", path, nil, query)
  end,
  ephemeralcontainers = function(parent, name)
    assert(parent.namespaced_, "can only get ephemeral containers when providing a namespace")
    local client = {}
    setmetatable(client, parent)
    client.client_ = parent.client_
    client.api_ = "ephemeralcontainers"
    client.path_ = string.format("/%s/%s", name, client.api_)

    function client.call(self, method, path, body, query, style)
      return parent:call(method, self.path_..path, body, query, style)
    end

    function client.raw_call(self, method, path, body, query, style)
      return parent:raw_call(method, self.path_..path, body, query, style)
    end

    function client.get(self)
      local obj, info, code = self:call("GET", "")
      return objects.NamespacedAPIObject:new(obj), info, code
    end

    function client.update(self, obj, query)
      if type(obj) == "string" then
        obj = yaml.load(obj)
      end
      local concat = {
        apiVersion = core_v1.version_string,
        kind = "EphemeralContainers"
      }
      for key, val in pairs(concat) do
        obj[key] = val
      end
      local resp, info, code = self:call("PUT", "", obj, query)
      return objects.NamespacedAPIObject:new(resp), info, code
    end

    function client.patch(self, patch, query, style)
      local resp, info, code = self:call("PATCH", "", patch, query, style)
      return objects.NamespacedAPIObject:new(resp), info, code
    end

    return client
  end
}
core_v1.Client.pods = utils.generate_object_client("pods", pod_base, true, true, true, extras)

-- PodTemplates
local podtemplate_base = {
  apiVersion = core_v1.version_string,
  kind = "PodTemplate",
}
core_v1.Client.podtemplates = utils.generate_object_client("podtemplates", podtemplate_base, true, false)

-- Services
local service_base = {
  apiVersion = core_v1.version_string,
  kind = "Service",
}
core_v1.Client.services = utils.generate_object_client("services", service_base, true, true, false)
core_v1.Client.svc = core_v1.Client.services

-- ConfigMaps
local configmap_base = {
  apiVersion = core_v1.version_string,
  kind = "ConfigMap",
}
core_v1.Client.configmaps = utils.generate_object_client("configmaps", configmap_base, true, false)
core_v1.Client.cm = core_v1.Client.configmaps

-- Secrets
local secret_base = {
  apiVersion = core_v1.version_string,
  kind = "Secret",
}
core_v1.Client.secrets = utils.generate_object_client("secrets", secret_base, true, false)
core_v1.Client.sec = core_v1.Client.secrets

-- ServiceAccounts
local service_account_base = {
  apiVersion = core_v1.version_string,
  kind = "ServiceAccount",
}
core_v1.Client.serviceaccounts = utils.generate_object_client("serviceaccounts", service_account_base, true, false)
core_v1.Client.sa = core_v1.Client.serviceaccounts

-- Endpoints
local endpoints_base = {
  apiVersion = core_v1.version_string,
  kind = "Endpoints",
}
core_v1.Client.endpoints = utils.generate_object_client("endpoints", endpoints_base, true, false)
core_v1.Client.ep = core_v1.Client.endpoints

-- PersistentVolumeClaims
local persistant_volume_claim_base = {
  apiVersion = core_v1.version_string,
  kind = "PersistentVolumeClaim",
}
core_v1.Client.persistentvolumeclaims = utils.generate_object_client("persistentvolumeclaims", persistant_volume_claim_base, true)
core_v1.Client.pvc = core_v1.Client.persistentvolumeclaims

-- PersistentVolumes
local persistant_volume_base = {
  apiVersion = core_v1.version_string,
  kind = "PersistentVolume",
}
core_v1.Client.persistentvolumes = utils.generate_object_client("persistentvolumes", persistant_volume_base, true)
core_v1.Client.pv = core_v1.Client.persistentvolumes

-- ReplicationControllers
local replication_controller_base = {
  apiVersion = core_v1.version_string,
  kind = "ReplicationController",
}
core_v1.Client.replicationcontrollers = utils.generate_object_client("replicationcontrollers", replication_controller_base, true)
core_v1.Client.rc = core_v1.Client.replicationcontrollers

-- LimitRanges
local limit_range_base = {
  apiVersion = core_v1.version_string,
  kind = "LimitRange",
}
core_v1.Client.limitranges = utils.generate_object_client("limitranges", limit_range_base, true, false)
core_v1.Client.limit = core_v1.Client.limitranges

-- ResourceQuota
local resource_quota_base = {
  apiVersion = core_v1.version_string,
  kind = "ResourceQuota",
}
core_v1.Client.resourcequotas = utils.generate_object_client("resourcequotas", resource_quota_base, true)
core_v1.Client.quota = core_v1.Client.resourcequotas

return core_v1


