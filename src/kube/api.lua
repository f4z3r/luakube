

local ltn12 = require "ltn12"
local https = require "ssl.https"
local json = require "json"

local api = {}

api.Client = {}

-- Client contructor.
function api.Client:new(config)
  local o = {
    _conf = config,
    _url = config:server_addr(),
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

-- Perform a raw API call. This returns a string of the body of the response.
function api.Client:raw_call(method, path, body)
  local url = self._url .. "/api/" .. path
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
    headers = self._conf:headers(),
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
    return resp, err_msg, code
  end
  return json.decode(resp)
end

return api
