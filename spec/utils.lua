#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
 Testing utilities.
]]--

local assert = require("luassert")
local say = require("say")
local json = require("json")

-- Custom assertions
local function starting_with(state, arguments)
  if not type(arguments[1]) == "string" or #arguments ~= 2 then
    return false
  end

  local sub = string.sub(arguments[1], 0, #arguments[2])
  return sub == arguments[2]
end

say:set("assertion.starting_with.positive", "Expected %s \nto start with: %s")
say:set("assertion.starting_with.negative", "Expected %s \nto not to start with: %s")
assert:register("assertion", "starting_with", starting_with,
                "assertion.starting_with.positive", "assertion.starting_with.negative")

local function ending_with(state, arguments)
  if not type(arguments[1]) == "string" or #arguments ~= 2 then
    return false
  end

  local start = #arguments[1] - #arguments[2] + 1
  local sub = string.sub(arguments[1], start, #arguments[1])
  return sub == arguments[2]
end

say:set("assertion.ending_with.positive", "Expected %s \nto end with: %s")
say:set("assertion.ending_with.negative", "Expected %s \nto not to end with: %s")
assert:register("assertion", "ending_with", ending_with,
                "assertion.ending_with.positive", "assertion.ending_with.negative")


local function containing(state, arguments)
  if not type(arguments[1]) == "string" or #arguments ~= 2 then
    return false
  end
  return string.match(arguments[1], arguments[2]) ~= nil
end

say:set("assertion.containing.positive", "Expected %s \nto contain: %s")
say:set("assertion.containing.negative", "Expected %s \nto not to contain: %s")
assert:register("assertion", "containing", containing,
                "assertion.containing.positive", "assertion.containing.negative")


-- Utility functions
local function run(cmd)
  local fh = io.popen(cmd, "r")
  local ctnt = fh:read("a")
  fh:close()
  return ctnt
end

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

local utils = {}

-- Kubernetes version against which the system tests are run
utils.KUBE_VERSION = "1.21.1"

function utils.initialize_deployments()
  local worked = os.execute("kubectl -n demo apply -f assets/deploy.yaml")
  worked = worked and os.execute("kubectl -n demo apply -f assets/svc.yaml")
  return worked
end

function utils.create_k3d_cluster()
  local logfile = os.tmpname()
  local time = os.date("%H%M%S", os.time())
  local name = "luakube-"..time
  os.execute(string.format("k3d cluster create %s -a 2 -s 1 --image=rancher/k3s:v%s-k3s1 > %s 2>&1",
                           name, utils.KUBE_VERSION, logfile))
  if not os.execute("kubectl cluster-info >> "..logfile) == 0 then
    error("failed to create k3d cluster for testing: "..logfile)
  end
  local username = "admin@k3d-"..name
  assert(initialize_sa(username))
  return name, function () delete_k3d_cluster(name, logfile) end
end

function utils.sleep(secs)
  os.execute("sleep "..secs)
end

function utils.assert_are_json_equal(arg1, arg2)
  arg1 = json.decode(arg1)
  arg2 = json.decode(arg2)
  assert.are.same(arg1, arg2)
end

return utils

