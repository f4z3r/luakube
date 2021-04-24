#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Module allowing to interact with the Kubernetes configuration.
]]--

local yaml = require "lyaml"
local fun = require "fun"

local KubeConfig = {}

function KubeConfig.get_default_path()
  local home = os.getenv("HOME")
  return home.."/.kube/config"
end

function KubeConfig:new(path)
  path = path or KubeConfig.get_default_path()
  local fh = io.open(path, "r")
  local o = yaml.load(fh:read("a"))
  fh:close()
  self.__index = self
  setmetatable(o, self)
  return o
end

function KubeConfig:context_names()
  return fun.iter(self.contexts)
    :map(function(v) return v.name end)
    :totable()
end

function KubeConfig:cluster_names()
  return fun.iter(self.clusters)
    :map(function(v) return v.name end)
    :totable()
end

function KubeConfig:cluster_name(ctxt)
  for _, context in ipairs(self.contexts) do
    if context.name == ctxt then
      return context.context.cluster
    end
  end
  return nil, "no cluster found for context: "..ctxt
end

function KubeConfig:cluster(name)
  for _, cluster in ipairs(self.clusters) do
    if cluster.name == name then
      return cluster.cluster
    end
  end
  return nil, "no cluster found with name: "..name
end

function KubeConfig:usernames()
  return fun.iter(self.users)
    :map(function(v) return v.name end)
    :totable()
end

function KubeConfig:username(ctxt)
  for _, context in ipairs(self.contexts) do
    if context.name == ctxt then
      return context.context.user
    end
  end
  return nil, "no username found for context: "..ctxt
end

function KubeConfig:user(name)
  for _, user in ipairs(self.users) do
    if user.name == name then
      return user.user
    end
  end
  return nil, "no user found with name: "..name
end




local conf = {}

conf.Config = {}


-- Configuration contructor. Not to be used directly in most cases.
function conf.Config:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  return o
end


-- Returns the list of available contexts in the configuration.
function conf.Config:contexts()
  return self._kube:context_names()
end

-- Returns the currently active cluster in the configuration.
function conf.Config:cluster()
  return assert(self._kube:cluster_name(self._ctxt))
end

-- Returns the list of available clusters in the configuration.
function conf.Config:clusters()
  return self._kube:cluster_names()
end

-- Returns the list of available contexts in the configuration.
function conf.Config:usernames()
  return self._kube:usernames()
end

-- Returns the user for the current context in the configuration.
function conf.Config:username()
  return assert(self._kube:username(self._ctxt))
end

-- Returns the server address currently configured
function conf.Config:server_addr()
  return self._addr
end

local function init_config(config)
  local user = config._kube:user(config:username())
  local cluster = config._kube:cluster(config:cluster())
  config._addr = cluster.server
  if user.token then
    config._token = user.token
  else
    return nil, "only token logins are currently supported"
  end
  return true
end

-- Returns the currently active context in the configuration. Pass an argument to set the current
-- context.
function conf.Config:context(ctxt)
  if ctxt then
    self._ctxt = ctxt
    assert(init_config(self))
  end
  return self._ctxt
end

-- Return a configuration loaded from the kube config at path and set to context ctxt.
function conf.from_kube_config(path, ctxt)
  local kube_config = KubeConfig:new(path)
  ctxt = ctxt or kube_config["current-context"]
  local config =  conf.Config:new{
    _kube = kube_config,
    _ctxt = ctxt,
  }
  assert(init_config(config))
  return config
end

return conf
