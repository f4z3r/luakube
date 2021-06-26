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

local cronjob_base = {
  apiVersion = batch_v1.version_string,
  kind = "CronJob",
}
batch_v1.Client.cronjobs = utils.generate_object_client("cronjobs", cronjob_base, true)
batch_v1.Client.cj = batch_v1.Client.cronjobs

return batch_v1
