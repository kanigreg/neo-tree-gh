local file_items = require("neo-tree.sources.common.file-items")
local log = require("neo-tree.log")
local renderer = require("neo-tree.ui.renderer")

local M = {}

local pr_files = function(state)
  if state.cached == true then
    return M.pr_files
  end

  local cmd = { "gh", "pr", "view", "--json", "files" }
  local system_obj = vim.system(cmd, { text = true })
  local complete = system_obj:wait(1000)

  if complete.code ~= 0 then
    log.error("Neotree: Can't load PR info from GitHub")
    return {}
  end

  local response = vim.json.decode(complete.stdout)
  M.pr_files = response.files
  state.cached = true
  return M.pr_files
end

M.get_pr_files = function(state)
  if state.loading then
    return
  end
  state.loading = true

  local context = file_items.create_context(state)
  -- Create root folder
  local root = file_items.create_item(context, state.path, "directory")
  root.name = vim.fn.fnamemodify(root.path, ":~")
  root.loaded = true
  root.search_pattern = state.search_pattern
  context.folders[root.path] = root

  -- Create nodes
  local files = pr_files(state)
  for _, file in ipairs(files) do
    local success, item = pcall(file_items.create_item, context, root.path .. "/" .. file.path, "file")
    if success then
      item.extra = {
        added_count = file.additions,
        deleted_count = file.deletions,
      }
    else
      log.error("Error creating item for " .. file.path .. ": " .. item)
    end
  end

  -- Expand all nodes
  state.default_expanded_nodes = {}
  for id, _ in pairs(context.folders) do
    table.insert(state.default_expanded_nodes, id)
  end
  -- Sort nodes
  file_items.advanced_sort(root.children, state)

  renderer.show_nodes({ root }, state)
  state.loading = false
end

return M
