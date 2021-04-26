

local ltn12 = require "ltn12"
local https = require "ssl.https"
local json = require "json"

local core_v1 = require "kube.api.core_v1"

local api = {}

api.Client = {}

-- Client contructor.
function api.Client:new(config)
  local o = {
    conf_ = config,
    url_ = config:server_addr(),
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

-- Perform a raw API call. This returns a string of the body of the response.
function api.Client:raw_call(method, path, body)
  local url = self.url_ .. "/api/" .. path
  local source
  if body then
    source = ltn12.source.string(body)
  end
  local resp = {}
  local params = {
    url = url,
    method = method,
    verify = "none",
    protocol = "any",
    source = source,
    sink = ltn12.sink.table(resp),
    headers = self.conf_:headers(),
  }
  local worked, code, _ = https.request(params)
  if not worked or code < 200 or code >= 300 then
    return nil, "failed to perform API call", code
  end
  return table.concat(resp)
end

-- Perform a raw API call which returns a table structure of the response.
function api.Client:call(method, path, body)
  local resp, err_msg, code = self:raw_call(method, path, body)
  if not resp then
    error("Code "..code..": "..(err_msg or "unknown error"))
  end
  return json.decode(resp)
end

-- Get a Core V1 API client
function api.Client:corev1()
  return core_v1.Client:new(self)
end

return api
