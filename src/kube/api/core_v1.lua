#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Core V1 API specification.
]]--

local utils = require "kube.api.utils"

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
core_v1.Client.namespaces = utils.generate_object_client("namespaces", ns_base, false, true, false)

-- Pods
local pod_base = {
  apiVersion = core_v1.version_string,
  kind = "Pod",
}
core_v1.Client.pods = utils.generate_object_client("pods", pod_base, true)
core_v1.Client.logs = function(self, ns, name, args)
  local path = string.format("/namespaces/%s/%s/%s/log", ns, "pods", name)
  return self:raw_call("GET", path, nil, args)
end

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

-- ConfigMaps
local configmap_base = {
  apiVersion = core_v1.version_string,
  kind = "ConfigMap",
}
core_v1.Client.configmaps = utils.generate_object_client("configmaps", configmap_base, true, false)

-- Secrets
local secret_base = {
  apiVersion = core_v1.version_string,
  kind = "Secret",
}
core_v1.Client.secrets = utils.generate_object_client("secrets", secret_base, true, false)

-- ServiceAccounts
local service_account_base = {
  apiVersion = core_v1.version_string,
  kind = "ServiceAccount",
}
core_v1.Client.serviceaccounts = utils.generate_object_client("serviceaccounts", service_account_base, true, false)

-- Endpoints
local endpoints_base = {
  apiVersion = core_v1.version_string,
  kind = "Endpoints",
}
core_v1.Client.endpoints = utils.generate_object_client("endpoints", endpoints_base, true, false)

return core_v1


