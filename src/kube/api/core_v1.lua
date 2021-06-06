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

core_v1.Client.new = utils.create_client("v1/")
core_v1.Client.call = utils.create_call()
core_v1.Client.raw_call = utils.create_raw_call()

local nodes = "nodes"
core_v1.Client.nodelist = utils.create_get_list(nodes)
core_v1.Client.nodes = utils.create_get_all(nodes)
core_v1.Client.node = utils.create_get_single(nodes)
core_v1.Client.node_status = utils.create_get_single_status(nodes)

local namespaces = "namespaces"
core_v1.Client.namespacelist = utils.create_get_list(namespaces)
core_v1.Client.namespaces = utils.create_get_all(namespaces)
core_v1.Client.namespace = utils.create_get_single(namespaces)
core_v1.Client.namespace_status = utils.create_get_single_status(namespaces)

local pods = "pods"
core_v1.Client.podlist = utils.create_get_list_ns(pods)
core_v1.Client.pods = utils.create_get_all_ns(pods)
core_v1.Client.pod = utils.create_get_single_ns(pods)
core_v1.Client.pod_status = utils.create_get_single_status_ns(pods)
core_v1.Client.logs = function(self, ns, name, args)
  local path = string.format("namespaces/%s/%s/%s/log", ns, pods, name)
  return self:raw_call("GET", path, nil, args)
end

return core_v1


