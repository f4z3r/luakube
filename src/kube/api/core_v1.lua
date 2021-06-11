#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Core V1 API specification.
]]--

local fun = require "fun"
local obj = require "kube.api.objects"
local utils = require "kube.api.utils"

local core_v1 = {}

core_v1.Client = {}

core_v1.Client.new = utils.generate_base("v1")

local node_base = {
  apiVersion = "v1",
  kind = "Node",
}
core_v1.Client.nodes = utils.generate_object_client("nodes", node_base, false)

local ns_base = {
  apiVersion = "v1",
  kind = "Namespace",
}
core_v1.Client.namespaces = utils.generate_object_client("namespaces", ns_base, false)

local pod_base = {
  apiVersion = "v1",
  kind = "Pod",
}
core_v1.Client.pods = utils.generate_object_client("pods", pod_base, true)
core_v1.Client.logs = function(self, ns, name, args)
  local path = string.format("/namespaces/%s/%s/%s/log", ns, "pods", name)
  return self:raw_call("GET", path, nil, args)
end

return core_v1


