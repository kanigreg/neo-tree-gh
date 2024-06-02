--This file should contain all commands meant to be used by mappings.
local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local M = {}

M.refresh = function(state)
  manager.refresh("gh", state)
end

cc._add_common_commands(M)
return M
