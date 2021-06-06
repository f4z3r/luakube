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

core_v1.Client.new = utils.generate_client("v1/")
core_v1.Client.call = utils.generate_call()
core_v1.Client.raw_call = utils.generate_raw_call()

local nodes = "nodes"
local node_base = {
  apiVersion = "v1",
  kind = "Node",
}
core_v1.Client.nodelist = utils.generate_get_list(nodes)
core_v1.Client.nodes = utils.generate_get_all(nodes)
core_v1.Client.node = utils.generate_get_single(nodes)
core_v1.Client.create_node = utils.generate_create(nodes, node_base)
core_v1.Client.delete_node = utils.generate_delete(nodes)
core_v1.Client.node_status = utils.generate_get_single_status(nodes)

local namespaces = "namespaces"
local ns_base = {
  apiVersion = "v1",
  kind = "Namespace",
}
core_v1.Client.namespacelist = utils.generate_get_list(namespaces)
core_v1.Client.namespaces = utils.generate_get_all(namespaces)
core_v1.Client.namespace = utils.generate_get_single(namespaces)
core_v1.Client.create_namespace = utils.generate_create(namespaces, ns_base)
core_v1.Client.delete_namespace = utils.generate_delete(namespaces)
core_v1.Client.namespace_status = utils.generate_get_single_status(namespaces)

local pods = "pods"
local pod_base = {
  apiVersion = "v1",
  kind = "Pod",
}
core_v1.Client.podlist = utils.generate_get_list_ns(pods)
core_v1.Client.pods = utils.generate_get_all_ns(pods)
core_v1.Client.pod = utils.generate_get_single_ns(pods)
core_v1.Client.create_pod = utils.generate_create_ns(pods, pod_base)
core_v1.Client.delete_pod = utils.generate_delete_ns(pods)
core_v1.Client.pod_status = utils.generate_get_single_status_ns(pods)
core_v1.Client.logs = function(self, ns, name, args)
  local path = string.format("namespaces/%s/%s/%s/log", ns, pods, name)
  return self:raw_call("GET", path, nil, args)
end

return core_v1


