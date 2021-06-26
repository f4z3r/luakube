#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Example on how to get logs for a container.
]]--

local config = require "kube.config"
local api = require "kube.api"

-- Use local kube config to connect to cluster
local conf = config.from_kube_config()
local global_client = api.Client:new(conf)

-- Get the Core V1 client
local client = global_client:corev1()

-- Get the last three lines of logs from the coredns container as a string
local container_logs = client:pods("kube-system"):logs("coredns-7448499f4d-6khqb",
                                                       {tailLines = 3, container = "coredns"})

-- Get the logs over the last 10 seconds for all containers in the pod
local last_logs = client:logs("kube-system"):logs("coredns-7448499f4d-6khqb", {sinceSeconds = 10})
