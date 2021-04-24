#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Testing utilities.
]]--


local utils = {}

local function delete_k3d_cluster(name, logfile)
  if not os.execute(string.format("k3d cluster delete %s >> %s 2>&1", name, logfile)) == 0 then
    error(string.format("failed to delete k3d cluster %s: %s", name, logfile))
  end
  assert(os.remove(logfile))
end

function utils.create_k3d_cluster()
  local logfile = os.tmpname()
  local time = os.date("%H%M%S", os.time())
  local name = "luakube-"..time
  os.execute(string.format("k3d cluster create %s > %s 2>&1", name, logfile))
  if not os.execute("kubectl cluster-info >> "..logfile) == 0 then
    error("failed to create k3d cluster for testing: "..logfile)
  end
  return name, function () delete_k3d_cluster(name, logfile) end
end

return utils

