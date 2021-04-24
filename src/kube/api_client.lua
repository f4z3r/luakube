
local api_client = {}

api_client.Client = {}

-- Client contructor.
function api_client.Client:new(config)
  local o = {
    configuration = config
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

return api_client
