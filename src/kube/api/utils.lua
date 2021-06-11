#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Collection of utility functions used to generate the API calls.
]]--


local yaml = require "lyaml"

local objects = require "kube.api.objects"

local utils = {}

function utils.generate_base(api)
  return function(parent, api_client)
    assert(api_client, 'API abstraction must be created from a client')
    local client = {}
    parent.__index = parent
    setmetatable(client, parent)
    client.client_ = api_client
    client.api_ = api
    client.call = function(self, method, path, body, query)
      return self.client_:call(method, self.api_..path, body, query)
    end
    client.raw_call = function(self, method, path, body, query)
      return self.client_:raw_call(method, self.api_..path, body, query)
    end
    return client
  end
end

local function converter(namespaced)
  local res = objects.APIObject
  if namespaced then
    res = objects.NamespacedAPIObject
  end
  return res
end

local function list_converter(namespaced)
  local res = objects.list_to_api_object
  if namespaced then
    res = objects.list_to_ns_api_object
  end
  return res
end

function utils.generate_object_client(api, concat, namespaced, with_status)
  return function(parent, ns)
    if ns then
      assert(namespaced, "cannot provide namespace on non-namespaced object type")
    end
    if with_status == nil then
      with_status = true
    end

    local client = {}
    parent.__index = parent
    setmetatable(client, parent)
    client.client_ = parent.client_
    client.api_ = api
    client.namespaced_ = ns and true or false
    if ns then
      client.path_ = string.format("/namespaces/%s/%s", ns, client.api_)
    else
      client.path_ = "/"..client.api_
    end

    function client.call(self, method, path, body, query)
      return parent:call(method, self.path_..path, body, query)
    end

    function client.raw_call(self, method, path, body, query)
      return parent:raw_call(method, self.path_..path, body, query)
    end

    function client.get(self, name, query)
      if not name or type(name) ~= "string" then
        query = query or name
        local objs = self:call("GET", "", nil, query)
        return list_converter(self)(objs)
      end
      assert(not namespaced or self.namespaced_, "can only get object by name when providing namespace")
      local obj = self:call("GET", "/"..name, nil, query)
      return converter(namespaced):new(obj)
    end

    if with_status then
      function client.status(self, name)
        assert(not namespaced or self.namespaced_, "can only get object status when providing namespace")
        local path = string.format("/%s/status",  name)
        local obj = self:call("GET", path)
        return obj.status
      end
    end

    function client.create(self, obj, query)
      if type(obj) == "string" then
        obj = yaml.load(obj)
      end
      for key, val in pairs(concat) do
        obj[key] = val
      end
      local path = ""
      local resp = nil
      if namespaced and not self.namespaced_ then
        path = string.format("/namespaces/%s/%s", obj.metadata.namespace, self.api_)
        resp = parent:call("POST", path, obj, query)
      else
        resp = self:call("POST", path, obj, query)
      end
      return converter(namespaced):new(resp)
    end

    function client.update(self, obj, query)
      if type(obj) == "string" then
        obj = yaml.load(obj)
      end
      for key, val in pairs(concat) do
        obj[key] = val
      end
      local path = "/"..obj.metadata.name
      local resp = nil
      if namespaced and not self.namespaced_ then
        path = string.format("/namespaces/%s/%s/%s", obj.metadata.namespace,
                             self.api_, obj.metadata.name)
        resp = parent:call("PUT", path, obj, query)
      else
        resp = self:call("PUT", path, obj, query)
      end
      return converter(namespaced):new(resp)
    end

    if with_status then
      function client.update_status(self, obj, query)
        if type(obj) == "string" then
          obj = yaml.load(obj)
        end
        for key, val in pairs(concat) do
          obj[key] = val
        end
        local path = string.format("/%s/status", obj.metadata.name)
        local resp = nil
        if namespaced and not self.namespaced_ then
          path = string.format("/namespaces/%s/%s/%s/status", obj.metadata.namespace,
                               self.api_, obj.metadata.name)
          resp = parent:call("PUT", path, obj, query)
        else
          resp = self:call("PUT", path, obj, query)
        end
        return converter(namespaced):new(resp)
      end
    end

    function client.delete(self, name, query)
      return self:call("DELETE", "/"..name, nil, query)
    end

    function client.list(self, query)
      local list = self:call("GET", "", nil, query)
      for idx, item in ipairs(list.items) do
        list.items[idx] = converter(namespaced):new(item)
      end
      return list
    end

    return client
  end
end

return utils
