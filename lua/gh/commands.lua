--This file should contain all commands meant to be used by mappings.
local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local vim = vim

local M = {}

M.refresh = function(state)
  state.cached = false
  manager.refresh("gh", state)
end

M.show_debug_info = function(state)
  local node = state.tree:get_node()
  print(vim.inspect(node))
end

cc._add_common_commands(M)
return M
