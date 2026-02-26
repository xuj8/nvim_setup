return {
  "MagicDuck/grug-far.nvim",
  opts = {
    transient = false,
    minSearchChars = 1,
    normalModeSearch = false,
    icons = {
      enabled = false,
    },
    engines = {
      ripgrep = {
        extraArgs = "--hidden --glob !.git",
      },
    },
    history = {
      autoSave = {
        enabled = true,
        onReplace = true,
        onSyncAll = true,
      },
    },
  },
  config = function(_, opts)
    local grug_far = require("grug-far")
    grug_far.setup(opts)

    local instance_name = "project-search"

    local function find_nvim_tree_window()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "NvimTree" then
          return win
        end
      end
      return nil
    end

    local function preferred_window_creation_command(tree_win)
      if tree_win ~= nil then
        -- If NvimTree is open, create a separate column to its left.
        return "leftabove vsplit"
      end
      -- Otherwise keep it on the left side.
      return "topleft vsplit"
    end

    local function run_in_window(win, fn)
      if win == nil or not vim.api.nvim_win_is_valid(win) then
        return fn()
      end

      local current = vim.api.nvim_get_current_win()
      if current ~= win then
        vim.api.nvim_set_current_win(win)
      end

      local ok, result = pcall(fn)
      if ok then
        return result
      end

      if vim.api.nvim_win_is_valid(current) then
        pcall(vim.api.nvim_set_current_win, current)
      end
      error(result)
    end

    local function tokenize_csv(value)
      local items = {}
      if type(value) ~= "string" or value == "" then
        return items
      end
      for token in string.gmatch(value, "([^,]+)") do
        local cleaned = vim.trim(token)
        if cleaned ~= "" then
          if
            (cleaned:sub(1, 1) == "'" and cleaned:sub(-1) == "'")
            or (cleaned:sub(1, 1) == '"' and cleaned:sub(-1) == '"')
          then
            cleaned = cleaned:sub(2, -2)
          end
          cleaned = vim.trim(cleaned)
          if cleaned ~= "" then
            table.insert(items, cleaned)
          end
        end
      end
      return items
    end

    local function default_prefills_from_legacy_filters()
      local include = tokenize_csv(vim.g.nvim_lean_live_grep_include_globs)
      local exclude = tokenize_csv(vim.g.nvim_lean_live_grep_exclude_globs)
      local lines = {}

      for _, pattern in ipairs(include) do
        table.insert(lines, pattern)
      end
      for _, pattern in ipairs(exclude) do
        if pattern:sub(1, 1) == "!" then
          table.insert(lines, pattern)
        else
          table.insert(lines, "!" .. pattern)
        end
      end

      if #lines == 0 then
        return {}
      end

      return {
        filesFilter = table.concat(lines, "\n"),
      }
    end

    local function get_or_open_project_search(prefills)
      local tree_win = find_nvim_tree_window()
      local window_creation_command = preferred_window_creation_command(tree_win)

      if grug_far.has_instance(instance_name) then
        local inst = grug_far.get_instance(instance_name)
        inst._context.options.windowCreationCommand = window_creation_command
        if inst:is_open() then
          inst:open()
        else
          run_in_window(tree_win, function()
            inst:open()
          end)
        end
        if prefills ~= nil then
          inst:update_input_values(prefills, false)
        end
        return inst
      end

      return run_in_window(tree_win, function()
        return grug_far.open({
          instanceName = instance_name,
          windowCreationCommand = window_creation_command,
          prefills = prefills or default_prefills_from_legacy_filters(),
        })
      end)
    end

    local function toggle_project_search()
      if grug_far.has_instance(instance_name) then
        local inst = grug_far.get_instance(instance_name)
        if inst:is_open() then
          inst:hide()
          return
        end
      end
      get_or_open_project_search()
    end

    vim.keymap.set("n", "<leader>sf", toggle_project_search, { desc = "Project text search (grug-far)" })
    vim.keymap.set("n", "<leader>sF", function()
      local inst = get_or_open_project_search()
      inst:goto_input("filesFilter")
    end, { desc = "Project search: focus files filter" })
    vim.keymap.set("n", "<leader>sR", function()
      local inst = get_or_open_project_search({ filesFilter = "", flags = "" })
      inst:goto_input("search")
      vim.notify("Cleared grug-far files filter and flags")
    end, { desc = "Project search: clear filters" })
    vim.keymap.set("n", "<leader>sw", function()
      get_or_open_project_search({
        search = vim.fn.expand("<cword>"),
      })
    end, { desc = "Project search word under cursor (grug-far)" })
  end,
}
