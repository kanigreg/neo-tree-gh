--This file should have all functions that are in the public api and either set
--or read the state of this source.

local vim = vim
local gh_files = require("gh.lib.items")

local M = {
  name = "gh",
  display_name = "留GitHub PR files",
}

M.get_node_stat = function(node)
  return {
    birthtime = { sec = 1692617750 },
    mtime = { sec = 1692617750 },
    size = 11453,
  }
end

M.navigate = function(state, path)
  state.path = path or state.path or vim.fn.getcwd()
  gh_files.get_pr_files(state)
end

M.setup = function()
  require("neo-tree.utils").register_stat_provider("pr_file_stats", M.get_node_stat)
end

return M
