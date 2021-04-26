#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Core V1 API specification.
]]--

local fun = require "fun"
local obj = require "kube.api.objects"

local core_v1 = {}

core_v1.Client = {}

function core_v1.Client:new(o)
  assert(o, "API clients need to be created with a superclient")
  local client = {}
  self.__index = self
  setmetatable(client, self)
  client.client_ = o
  client.api_ = "v1/"
  return client
end

function core_v1.Client:call(method, path, body)
  return self.client_:call(method, self.api_..path, body)
end

function core_v1.Client:namespacelist()
  return self:call("GET", "namespaces")
end

function core_v1.Client:namespaces()
  local namespaces = self:call("GET", "namespaces")
  return fun.iter(namespaces.items)
    :map(function(v) return obj.APIObject:new(v) end)
    :totable()
end

function core_v1.Client:namespace(name)
  local ns = self:call("GET", "namespaces/"..name)
  return obj.APIObject:new(ns)
end

return core_v1


