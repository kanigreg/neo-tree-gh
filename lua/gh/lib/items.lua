local file_items = require("neo-tree.sources.common.file-items")
local log = require("neo-tree.log")
local renderer = require("neo-tree.ui.renderer")

local M = {
  pr = {},
}

local fill_with_comment_info = function(comments)
  for path, comment_nodes in pairs(comments) do
    if M.pr.files[path] then
      M.pr.files[path].comments = comment_nodes
    end
  end
end

local load_pr_comments = function(state)
  if state.cached == true or M.pr.files == nil then
    return
  end

  local jq = [[ 
    reduce .[] as {$path, $body, $line} 
      ({}; .[$path] += [{$body, $line}])
  ]]
  local cmd = { "gh", "api", "repos/{owner}/{repo}/pulls/" .. M.pr.number .. "/comments", "--jq", jq }
  local complete = vim.system(cmd, { text = true }):wait(2000)

  if complete.code ~= 0 then
    log.error("Neotree: Can't load PR comments from repo")
    return
  end

  local comments = vim.json.decode(complete.stdout)
  fill_with_comment_info(comments)
end

local load_pr_files = function(state)
  if state.cached == true then
    return
  end

  local jq = [[ 
    {
      number: .number, 
      files: reduce .files[] as {$path, $additions, $deletions} 
        ({}; .[$path] = {$additions, $deletions})
    } 
  ]]
  local cmd = { "gh", "pr", "view", "--json", "files,number", "--jq", jq }
  local complete = vim.system(cmd, { text = true }):wait(1000)

  if complete.code ~= 0 then
    log.error("Neotree: Can't load PR info from repo")
    return
  end

  M.pr = vim.json.decode(complete.stdout)
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

  -- Load info from remote repository
  load_pr_files(state)
  load_pr_comments(state)
  state.cached = true

  local files = M.pr.files or {}
  -- Create nodes
  for path, file in pairs(files) do
    local success, item = pcall(file_items.create_item, context, root.path .. "/" .. path, "file")
    if success then
      item.extra = {
        comments = file.comments,
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
