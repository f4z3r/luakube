#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Collection of objects returned from API calls.
]]--

local objects = {}

objects.APIObject = {}

function objects.APIObject:new(o)
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
  return self.metdata.namespace
end

return objects
