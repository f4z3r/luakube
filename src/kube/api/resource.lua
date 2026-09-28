-- Generic client constructed from an APIResource discovery entry.
local Resource = {}
Resource.__index = Resource

local function segment(value, description)
  assert(type(value) == "string" and value ~= "", description .. " is required")
  return (
    value:gsub("([^A-Za-z0-9%_%.%-%~])", function(char)
      return string.format("%%%02X", string.byte(char))
    end)
  )
end

function Resource:new(client, metadata, namespace, subresource)
  return setmetatable({
    client_ = client,
    metadata = metadata,
    namespace_ = namespace,
    subresource_ = subresource,
  }, self)
end

function Resource:namespace(name)
  assert(self.metadata.namespaced, self.metadata.name .. " is cluster-scoped")
  segment(name, "namespace")
  return Resource:new(self.client_, self.metadata, name, self.subresource_)
end

function Resource:subresource(name)
  assert(not self.subresource_, "already addressing a subresource")
  local sub = self.metadata.subresources[name]
  assert(sub, "subresource " .. tostring(name) .. " is not available for " .. self.metadata.name)
  return Resource:new(self.client_, self.metadata, self.namespace_, sub)
end

function Resource:allows(verb)
  return (self.subresource_ or self.metadata).verbs[verb] == true
end

function Resource:require_verb(verb)
  assert(self:allows(verb), self.metadata.name .. " does not support " .. verb)
end

function Resource:path(name)
  local path = self.metadata.path
  if self.namespace_ then
    path = path .. "/namespaces/" .. segment(self.namespace_, "namespace")
  end
  path = path .. "/" .. segment(self.metadata.name, "resource")
  if name ~= nil then
    path = path .. "/" .. segment(name, "name")
  end
  if self.subresource_ then
    assert(name, "subresource requests require an object name")
    path = path .. "/" .. segment(self.subresource_.name, "subresource")
  end
  return path
end

function Resource:require_namespace()
  assert(not self.metadata.namespaced or self.namespace_, "namespace is required for " .. self.metadata.name)
end

-- For unusual virtual subresources (such as eviction), request() exposes the
-- same path construction without inventing a dedicated method for each one.
function Resource:request(method, name, body, query, style)
  self:require_namespace()
  return self.client_:call(method, self:path(name), body, query, style)
end

function Resource:get(name, query)
  self:require_verb("get")
  self:require_namespace()
  segment(name, "name")
  return self.client_:call("GET", self:path(name), nil, query)
end

function Resource:get_raw(name, query)
  self:require_verb("get")
  self:require_namespace()
  segment(name, "name")
  return self.client_:raw_call("GET", self:path(name), nil, query)
end

function Resource:list(query)
  assert(not self.subresource_, "cannot list a subresource")
  self:require_verb("list")
  return self.client_:call("GET", self:path(), nil, query)
end

local function prepare(self, obj)
  assert(type(obj) == "table", "resource body must be a table")
  local copy = {}
  for key, value in pairs(obj) do
    copy[key] = value
  end
  if not self.subresource_ then
    copy.apiVersion = copy.apiVersion or self.metadata.group_version
    copy.kind = copy.kind or self.metadata.kind
  end
  if self.namespace_ then
    local metadata = {}
    for key, value in pairs(obj.metadata or {}) do
      metadata[key] = value
    end
    assert(
      not metadata.namespace or metadata.namespace == self.namespace_,
      "body namespace does not match resource namespace"
    )
    metadata.namespace = self.namespace_
    copy.metadata = metadata
  end
  return copy
end

function Resource:create(obj, query)
  assert(not self.subresource_, "use request() for subresource actions")
  self:require_verb("create")
  self:require_namespace()
  return self.client_:call("POST", self:path(), prepare(self, obj), query)
end

function Resource:replace(obj, query)
  self:require_verb("update")
  self:require_namespace()
  local body = prepare(self, obj)
  local name = assert(body.metadata and body.metadata.name, "metadata.name is required")
  segment(name, "name")
  return self.client_:call("PUT", self:path(name), body, query)
end

Resource.update = Resource.replace

function Resource:patch(name, patch, query, style)
  self:require_verb("patch")
  self:require_namespace()
  segment(name, "name")
  return self.client_:call("PATCH", self:path(name), patch, query, style)
end

function Resource:delete(name, query, body)
  self:require_verb("delete")
  self:require_namespace()
  segment(name, "name")
  return self.client_:call("DELETE", self:path(name), body, query)
end

function Resource:delete_collection(body, query)
  assert(not self.subresource_, "cannot delete a collection of subresources")
  self:require_verb("deletecollection")
  self:require_namespace()
  return self.client_:call("DELETE", self:path(), body, query)
end

return Resource
