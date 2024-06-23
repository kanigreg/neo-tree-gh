-- This file contains the built-in components. Each componment is a function
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

local common = require("neo-tree.sources.common.components")
local highlights = require("neo-tree.ui.highlights")

local M = {}

M.name = function(config, node)
  local highlight = config.highlight or highlights.FILE_NAME
  local text
  if node.type == "directory" then
    highlight = highlights.DIRECTORY_NAME
  end
  if node:get_depth() == 1 then
    highlight = highlights.ROOT_NAME
  end
  if node.type == "file" and node.extra.comments ~= nil then
    highlight = highlights.GIT_CONFLICT
    text = node.name .. " #" .. #node.extra.comments
  end
  return {
    text = text or node.name,
    highlight = highlight,
  }
end

return vim.tbl_deep_extend("force", common, M)
