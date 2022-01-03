#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Networking V1 API specification.
]]--

local utils = require "kube.api.utils"

local networking_v1 = {}

networking_v1.Client = {}

networking_v1.version_string = "networking.k8s.io/v1"

networking_v1.Client.new = utils.generate_base(networking_v1.version_string)

-- Ingresses
local ingress_base = {
  apiVersion = networking_v1.version_string,
  kind = "Ingress",
}
networking_v1.Client.ingresses = utils.generate_object_client("ingresses", ingress_base, true, true, true)
networking_v1.Client.ing = networking_v1.Client.ingresses


-- IngressClasses
local ingress_class_base = {
  apiVersion = networking_v1.version_string,
  kind = "IngressClass",
}
networking_v1.Client.ingressclasses = utils.generate_object_client("ingressclasses", ingress_class_base, false, false, true)
networking_v1.Client.ing = networking_v1.Client.ingresses

return networking_v1
