#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Testing utilities.
]]--


local function run(cmd)
  local fh = io.popen(cmd, "r")
  local ctnt = fh:read("a")
  fh:close()
  return ctnt
end

local utils = {}

local function delete_k3d_cluster(name, logfile)
  if not os.execute(string.format("k3d cluster delete %s >> %s 2>&1", name, logfile)) == 0 then
    error(string.format("failed to delete k3d cluster %s: %s", name, logfile))
  end
  assert(os.remove(logfile))
end

local function initialize_sa(user)
  local worked = os.execute("kubectl create ns demo")
  worked = worked and os.execute("kubectl apply -f assets/sa.yaml")
  worked = worked and os.execute("kubectl apply -f assets/crb.yaml")
  local secret = run('kubectl -n demo get sa/admin -o jsonpath="{.secrets[0].name}"')
  local token = run(string.format('kubectl -n demo get secret %s -o json | jq -r ".data.token" | base64 -d', secret))
  worked = worked and os.execute(string.format("kubectl config set-credentials %s --token=%s", user, token))
  return worked
end

function utils.create_k3d_cluster()
  local logfile = os.tmpname()
  local time = os.date("%H%M%S", os.time())
  local name = "luakube-"..time
  os.execute(string.format("k3d cluster create %s > %s 2>&1", name, logfile))
  if not os.execute("kubectl cluster-info >> "..logfile) == 0 then
    error("failed to create k3d cluster for testing: "..logfile)
  end
  local username = "admin@k3d-"..name
  assert(initialize_sa(username))
  return name, function () delete_k3d_cluster(name, logfile) end
end

return utils

