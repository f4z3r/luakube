

local ltn12 = require "ltn12"
local https = require "ssl.https"
local json = require "json"

local core_v1 = require "kube.api.core_v1"

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
function api.Client:new(config, mock)
  mock = mock or false
  local o = {
    conf_ = config,
    url_ = config:server_addr(),
    mock_ = mock
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

-- Perform a raw API call. This returns a string of the body of the response.
function api.Client:raw_call(method, path, body, query)
  local url = self.url_ .. "/api/" .. path
  if query then
    local query_str = build_query(query)
    url = url .. '?' .. query_str
  end
  local headers = self.conf_:headers()
  local source
  local body_str = ""
  if body then
    body_str = json.encode(body)
    source = ltn12.source.string(body_str)
    headers["Content-Type"] = "application/json";
    headers["Content-Length"] = #body_str;
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
  }
  local info = {
    method = method,
    url = url,
    headers = headers,
    body = body
  }
  if self.mock_ then
    return '{"items": []}', info
  end
  local worked, code, _ = https.request(params)
  if not worked or code < 200 or code >= 300 then
    return nil, string.format("failed to perform API call: %s %s\n%s", method, url, body_str), code
  end
  return table.concat(resp), info
end

-- Perform a raw API call which returns a table structure of the response.
function api.Client:call(method, path, body, query)
  local resp, msg, code = self:raw_call(method, path, body, query)
  if not resp then
    error("Code "..code..": "..(msg or "unknown error"))
  end
  return json.decode(resp), msg
end

-- Get a Core V1 API client
function api.Client:corev1()
  return core_v1.Client:new(self)
end

return api
