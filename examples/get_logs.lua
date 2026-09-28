#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Example on how to get logs for a container.
]]--

local config = require "kube.config"
local api = require "kube.api"

local client = api.Client:new(config.from_kube_config(os.getenv("KUBECONFIG")))
local logs = client:resource("v1", "Pod"):namespace("kube-system"):subresource("log")
local pod_name = "coredns-7448499f4d-6khqb" -- replace with a pod on your cluster

-- Get the last three lines of logs from the coredns container as a string.
local container_logs = logs:get_raw(pod_name, { tailLines = 3, container = "coredns" })

-- Get logs from the same container over the last 10 seconds.
local last_logs = logs:get_raw(pod_name, { sinceSeconds = 10, container = "coredns" })

print(container_logs, last_logs)
