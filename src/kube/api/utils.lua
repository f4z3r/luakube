#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Collection of utility functions used to generate the API calls.
]]--


local objects = require "kube.api.objects"

local utils = {}

function utils.create_client(api)
  return function(self, o)
    assert(o, "API clients need to be created with a superclient")
    local client = {}
    self.__index = self
    setmetatable(client, self)
    client.client_ = o
    client.api_ = api
    return client
  end
end

function utils.create_call()
  return function(self, method, path, body, query)
    return self.client_:call(method, self.api_..path, body, query)
  end
end

function utils.create_raw_call()
  return function(self, method, path, body, query)
    return self.client_:raw_call(method, self.api_..path, body, query)
  end
end

function utils.create_get_single(obj_type)
  return function(self, name)
    local path = string.format("%s/%s", obj_type, name)
    local obj = self:call("GET", path)
    return objects.APIObject:new(obj)
  end
end

function utils.create_get_single_status(obj_type)
  return function(self, name)
    local path = string.format("%s/%s/status", obj_type, name)
    local obj = self:call("GET", path)
    return obj.status
  end
end

function utils.create_get_all(obj_type)
  return function(self)
    local path = string.format("%s", obj_type)
    local objs = self:call("GET", path)
    return objects.list_to_api_object(objs)
  end
end

function utils.create_get_list(obj_type)
  return function(self)
    local list = self:call("GET", obj_type)
    for idx, item in ipairs(list.items) do
      list.items[idx] = objects.APIObject:new(item)
    end
    return list
  end
end

function utils.create_get_single_ns(obj_type)
  return function(self, ns, name)
    local path = string.format("namespaces/%s/%s/%s", ns, obj_type, name)
    local obj = self:call("GET", path)
    return objects.NamespacedAPIObject:new(obj)
  end
end

function utils.create_get_single_status_ns(obj_type)
  return function(self, ns, name)
    local path = string.format("namespaces/%s/%s/%s/status", ns, obj_type, name)
    local obj = self:call("GET", path)
    return obj.status
  end
end

function utils.create_get_all_ns(obj_type)
  return function(self, ns)
    local path = string.format("namespaces/%s/%s", ns, obj_type)
    local objs = self:call("GET", path)
    return objects.list_to_ns_api_object(objs)
  end
end

function utils.create_get_list_ns(obj_type)
  return function(self)
    local list = self:call("GET", obj_type)
    for idx, item in ipairs(list.items) do
      list.items[idx] = objects.NamespacedAPIObject:new(item)
    end
    return list
  end
end

return utils
