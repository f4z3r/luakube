-- HTTP client for Kubernetes API paths. Authentication still comes from kube.config.

local https = require("ssl.https")
local json = require("dkjson")
local ltn12 = require("ltn12")

local Discovery = require("kube.api.discovery")
local Resource = require("kube.api.resource")

local function encode(str)
  return (
    tostring(str):gsub("([^A-Za-z0-9%_%.%-%~])", function(char)
      return string.format("%%%02X", string.byte(char))
    end)
  )
end

local function build_query(data)
  local keys, fields = {}, {}
  for key in pairs(data) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  for _, key in ipairs(keys) do
    if data[key] ~= nil then
      fields[#fields + 1] = encode(key) .. "=" .. encode(data[key])
    end
  end
  return table.concat(fields, "&")
end

local patch_types = {
  merge = "application/merge-patch+json",
  json = "application/json-patch+json",
  strategic = "application/strategic-merge-patch+json",
  apply = "application/apply-patch+yaml",
}

local api = { Client = {} }
api.Client.__index = api.Client

-- An options table can supply a transport for testing.
function api.Client:new(config, options)
  options = options or {}
  assert(type(options) == "table", "client options must be a table")
  local client = setmetatable({
    conf_ = config,
    url_ = assert(config:server_addr(), "Kubernetes server address is required"):gsub("/+$", ""),
    https_ = options.transport or https,
    panic_ = options.panic or false,
  }, self)
  client.discovery_ = Discovery:new(client)
  return client
end

-- Paths are absolute API paths, such as /api/v1 or /apis/apps/v1.
function api.Client:raw_call(method, path, body, query, style)
  assert(type(path) == "string" and path:sub(1, 1) == "/", "API path must start with /")
  local url = self.url_ .. path
  if query then
    local suffix = build_query(query)
    if suffix ~= "" then
      url = url .. "?" .. suffix
    end
  end

  local headers = self.conf_:headers()
  local source, body_str
  if body ~= nil then
    if method == "PATCH" then
      local content_type = assert(patch_types[style or "merge"], "unknown patch style")
      headers["Content-Type"] = content_type
      if type(body) == "string" then
        assert(style == "apply", "raw string bodies are only supported for apply patches")
        body_str = body
      else
        body_str = json.encode(body)
      end
    else
      headers["Content-Type"] = "application/json"
      body_str = type(body) == "string" and body or json.encode(body)
    end
    headers["Content-Length"] = #body_str
    source = ltn12.source.string(body_str)
  end

  local resp = {}
  local info = { method = method, url = url, headers = headers, body = body }
  local worked, code, transport_error = self.https_.request({
    url = url,
    method = method,
    source = source,
    sink = ltn12.sink.table(resp),
    headers = headers,
    certificate = self.conf_:cert(),
    key = self.conf_:key(),
    verify = "none",
    protocol = "any",
  })
  local response = table.concat(resp)
  if not worked or type(code) ~= "number" or code < 200 or code >= 300 then
    local message =
      string.format("Kubernetes API %s %s failed (%s): %s", method, url, tostring(code or transport_error), response)
    if self.panic_ then
      error(message, 2)
    end
    return nil, message, code
  end
  return response, info, code
end

function api.Client:call(method, path, body, query, style)
  local response, info, code = self:raw_call(method, path, body, query, style)
  if not response then
    return nil, info, code
  end
  if response == "" then
    return nil, info, code
  end
  return json.decode(response), info, code
end

function api.Client:discover(group_version, refresh)
  return self.discovery_:resources(group_version, refresh)
end

function api.Client:resource(group_version, kind_or_name)
  local metadata = self.discovery_:resolve(group_version, kind_or_name)
  return Resource:new(self, metadata)
end

return api
