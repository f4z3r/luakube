#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Collection of utility functions used to generate the API calls.
]]--


local yaml = require "lyaml"

local objects = require "kube.api.objects"

local utils = {}

function utils.generate_client(api)
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

function utils.generate_call()
  return function(self, method, path, body, query)
    return self.client_:call(method, self.api_..path, body, query)
  end
end

function utils.generate_raw_call()
  return function(self, method, path, body, query)
    return self.client_:raw_call(method, self.api_..path, body, query)
  end
end

function utils.generate_get_single(obj_type)
  return function(self, name)
    local path = string.format("%s/%s", obj_type, name)
    local obj = self:call("GET", path)
    return objects.APIObject:new(obj)
  end
end

function utils.generate_get_single_status(obj_type)
  return function(self, name)
    local path = string.format("%s/%s/status", obj_type, name)
    local obj = self:call("GET", path)
    return obj.status
  end
end

function utils.generate_create(obj_type, concat)
  return function(self, obj, query)
    if type(obj) == "string" then
      obj = yaml.load(obj)
    end
    for key, val in pairs(concat) do
      obj[key] = val
    end
    local resp = self:call("POST", obj_type, obj, query)
    return objects.APIObject:new(resp)
  end
end

function utils.generate_delete(obj_type)
  return function(self, name, query)
    local path = string.format("%s/%s", obj_type, name)
    return self:call("DELETE", path, nil, query)
  end
end

function utils.generate_get_all(obj_type)
  return function(self, query)
    local path = string.format("%s", obj_type)
    local objs = self:call("GET", path, nil, query)
    return objects.list_to_api_object(objs)
  end
end

function utils.generate_get_list(obj_type)
  return function(self, query)
    local list = self:call("GET", obj_type, nil, query)
    for idx, item in ipairs(list.items) do
      list.items[idx] = objects.APIObject:new(item)
    end
    return list
  end
end

function utils.generate_get_single_ns(obj_type)
  return function(self, ns, name)
    local path = string.format("namespaces/%s/%s/%s", ns, obj_type, name)
    local obj = self:call("GET", path)
    return objects.NamespacedAPIObject:new(obj)
  end
end

function utils.generate_get_single_status_ns(obj_type)
  return function(self, ns, name)
    local path = string.format("namespaces/%s/%s/%s/status", ns, obj_type, name)
    local obj = self:call("GET", path)
    return obj.status
  end
end

function utils.generate_create_ns(obj_type, concat)
  return function(self, ns, obj, query)
    if type(obj) == "string" then
      obj = yaml.load(obj)
    end
    for key, val in pairs(concat) do
      obj[key] = val
    end
    local path = string.format("namespaces/%s/%s", ns, obj_type)
    local resp = self:call("POST", path, obj, query)
    return objects.NamespacedAPIObject:new(resp)
  end
end

function utils.generate_delete_ns(obj_type)
  return function(self, ns, name, query)
    local path = string.format("namespaces/%s/%s/%s", ns, obj_type, name)
    return self:call("DELETE", path, nil, query)
  end
end

function utils.generate_get_all_ns(obj_type)
  return function(self, ns, query)
    local path = string.format("namespaces/%s/%s", ns, obj_type)
    if type(ns) ~= "string" then
      path = obj_type
      query = ns
    end
    local objs = self:call("GET", path, nil, query)
    return objects.list_to_ns_api_object(objs)
  end
end

function utils.generate_get_list_ns(obj_type)
  return function(self, ns, query)
    local path = string.format("namespaces/%s/%s", ns, obj_type)
    if type(ns) ~= "string" then
      path = obj_type
      query = ns
    end
    local list = self:call("GET", path, nil, query)
    for idx, item in ipairs(list.items) do
      list.items[idx] = objects.NamespacedAPIObject:new(item)
    end
    return list
  end
end

return utils
