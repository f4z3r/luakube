--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 API base module that is used to obtain a general client.
]]--


local ltn12 = require "ltn12"
local https = require "ssl.https"
local json = require "json"

local core_v1 = require "kube.api.core_v1"
local batch_v1 = require "kube.api.batch_v1"
local apps_v1 = require "kube.api.apps_v1"
local networking_v1 = require "kube.api.networking_v1"

-- Mock client used to fake https requests. Always returns empty response and never fails.
local mock_https = {
  request = function(params)
    local source = ltn12.source.string('{"items": []}')
    ltn12.pump.all(source, params.sink)
    return true, 200, ""
  end,
}

-- TODO(@jakob): cleanup query encoding functions
local function encode(str)
  return (str:gsub("([^A-Za-z0-9%_%.%-%~])", function(v)
      return string.upper(string.format("%%%02x", string.byte(v)))
  end))
end

local function replace_space_encoding(str)
  str = encode(str)
  return str:gsub('%%20', '+')
end

local function build_query(data)
  local query = {}
  local sep = '&'
  local keys = {}
  for k in pairs(data) do
    keys[#keys+1] = k
  end
  table.sort(keys)
  for _,name in ipairs(keys) do
    name = encode(tostring(name))
    local value = replace_space_encoding(tostring(data[name]))
    if value ~= "" then
      query[#query+1] = string.format('%s=%s', name, value)
    else
      query[#query+1] = name
    end
  end
  return table.concat(query, sep)
end

local api = {}

api.Client = {}

-- Client contructor.
function api.Client:new(config, panic, mock)
  mock = mock or false
  panic = panic or false
  local o = {
    conf_ = config,
    url_ = config:server_addr(),
    api_base_ = "api",
    https_ = mock and mock_https or https,
    panic_ = panic,
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

-- Perform a raw API call. This returns a string of the body of the response.
function api.Client:raw_call(method, path, body, query, style)
  local url = string.format("%s/%s/%s", self.url_, self.api_base_, path)
  if query then
    local query_str = build_query(query)
    url = url .. '?' .. query_str
  end
  style = style or "merge"
  local headers = self.conf_:headers()
  local source = nil
  local body_str = ""
  if body then
    body_str = json.encode(body)
    source = ltn12.source.string(body_str)
    headers["Content-Length"] = #body_str;
    if method == "PATCH" then
      headers["Content-Type"] = string.format("application/%s-patch+json", style);
    else
      headers["Content-Type"] = "application/json";
    end
  end
  local resp = {}
  local params = {
    url = url,
    method = method,
    verify = "none",
    protocol = "any",
    source = source,
    sink = ltn12.sink.table(resp),
    headers = headers,
    certificate = self.conf_:cert(),
    key = self.conf_:key()
  }
  local info = {
    method = method,
    url = url,
    headers = headers,
    body = body
  }
  local worked, code, _ = self.https_.request(params)
  if not worked or code < 200 or code >= 300 then
    local err_msg = string.format("failed to perform API call: %s %s\nbody: %s\nerror: %s", method, url, body_str, table.concat(resp))
    if self.panic_ then
      error("Code "..code..": "..(err_msg or "unknown error"))
    end
    return table.concat(resp), err_msg, code
  end
  return table.concat(resp), info, code
end

-- Perform a raw API call which returns a table structure of the response.
function api.Client:call(method, path, body, query, style)
  local resp, info, code = self:raw_call(method, path, body, query, style)
  return json.decode(resp), info, code
end

-- Get a Core V1 API client
function api.Client:corev1()
  self.api_base_ = "api"
  return core_v1.Client:new(self)
end

-- Get a Batch V1 API client
function api.Client:batchv1()
  self.api_base_ = "apis"
  return batch_v1.Client:new(self)
end

-- Get a Apps V1 API client
function api.Client:appsv1()
  self.api_base_ = "apis"
  return apps_v1.Client:new(self)
end

-- Get a Networking V1 API client
function api.Client:networkingv1()
  self.api_base_ = "apis"
  return networking_v1.Client:new(self)
end

return api
