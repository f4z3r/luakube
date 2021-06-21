#!/usr/bin/env lua

--[[
Author: Jakob Beckmann <beckmann_jakob@hotmail.fr>
Description:
  Batch V1 API specification.
]]--

local utils = require "kube.api.utils"

local batch_v1 = {}

batch_v1.Client = {}

batch_v1.version_string = "batch/v1"

batch_v1.Client.new = utils.generate_base(batch_v1.version_string)

local job_base = {
  apiVersion = batch_v1.version_string,
  kind = "Job",
}
batch_v1.Client.jobs = utils.generate_object_client("jobs", job_base, true)

return batch_v1
