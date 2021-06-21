#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Collection of objects returned from API calls.
]]--

local fun = require "fun"

local objects = {}

objects.Response = {}

function objects.Response:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  return o
end

function objects.Response:is_failure()
  return self.kind == "Status" and self.status == "Failure"
end

objects.APIObject = objects.Response:new({})

function objects.APIObject:new(o)
  if o and o.is_failure and o:is_failure() then
    return o
  end
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  return o
end

function objects.APIObject:name()
  return self.metadata.name
end

function objects.APIObject:labels()
  return self.metadata.labels or {}
end

function objects.APIObject:annotations()
  return self.metadata.annotations or {}
end

function objects.APIObject:uid()
  return self.metadata.uid
end

function objects.APIObject:creation_timestamp()
  return self.metadata.creationTimestamp
end

objects.NamespacedAPIObject = objects.APIObject:new({})

function objects.NamespacedAPIObject:namespace()
  return self.metadata.namespace
end

function objects.list_to_api_object(list)
  return fun.iter(list["items"])
    :map(function(item) return objects.APIObject:new(item) end)
    :totable()
end

function objects.list_to_ns_api_object(list)
  return fun.iter(list["items"])
    :map(function(item) return objects.NamespacedAPIObject:new(item) end)
    :totable()
end

return objects
