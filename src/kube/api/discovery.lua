-- Lazy discovery for one group/version at a time. Works with built-ins, CRDs and
-- aggregated API servers, including clusters without aggregated discovery.
local Discovery = {}
Discovery.__index = Discovery

local function api_path(group_version)
  assert(type(group_version) == "string", "group/version must be a string")
  if group_version:match("^v%d[%w]*$") then
    return "/api/" .. group_version
  end
  local group, version = group_version:match("^([%w%.%-]+)/([%w]+)$")
  assert(group and version and version:match("^v%d"), "invalid group/version: " .. group_version)
  return "/apis/" .. group .. "/" .. version
end

function Discovery:new(client)
  return setmetatable({ client_ = client, cache_ = {} }, self)
end

function Discovery:resources(group_version, refresh)
  local path = api_path(group_version)
  if self.cache_[group_version] and not refresh then
    return self.cache_[group_version]
  end

  local document, err = self.client_:call("GET", path)
  if not document then
    error(err or "empty discovery response", 2)
  end
  assert(
    document.groupVersion == group_version and type(document.resources) == "table",
    "invalid discovery response for " .. group_version
  )

  local resources, by_name = {}, {}
  for _, entry in ipairs(document.resources) do
    if type(entry.name) == "string" and not entry.name:find("/", 1, true) then
      local verbs = {}
      for _, verb in ipairs(entry.verbs or {}) do
        verbs[verb] = true
      end
      local descriptor = {
        group_version = group_version,
        path = path,
        name = entry.name,
        kind = entry.kind,
        namespaced = entry.namespaced,
        verbs = verbs,
        singular_name = entry.singularName,
        short_names = entry.shortNames or {},
        subresources = {},
      }
      resources[#resources + 1] = descriptor
      by_name[entry.name] = descriptor
    end
  end
  for _, entry in ipairs(document.resources) do
    local parent, sub
    if type(entry.name) == "string" then
      parent, sub = entry.name:match("^([^/]+)/([^/]+)$")
    end
    if parent and by_name[parent] then
      local verbs = {}
      for _, verb in ipairs(entry.verbs or {}) do
        verbs[verb] = true
      end
      by_name[parent].subresources[sub] = { name = sub, kind = entry.kind, verbs = verbs }
    end
  end
  self.cache_[group_version] = resources
  return resources
end

function Discovery:resolve(group_version, kind_or_name)
  assert(type(kind_or_name) == "string" and kind_or_name ~= "", "resource kind or name is required")
  local resources = self:resources(group_version)
  -- An exact REST resource name takes priority over a kind or short name.
  for _, resource in ipairs(resources) do
    if resource.name == kind_or_name then
      return resource
    end
  end
  local found
  for _, resource in ipairs(resources) do
    local matches = resource.kind == kind_or_name or resource.singular_name == kind_or_name
    for _, short in ipairs(resource.short_names) do
      if short == kind_or_name then
        matches = true
      end
    end
    if matches then
      if found then
        error("ambiguous resource " .. kind_or_name .. " in " .. group_version, 2)
      end
      found = resource
    end
  end
  if not found then
    error("unknown resource " .. kind_or_name .. " in " .. group_version, 2)
  end
  return found
end

return Discovery
