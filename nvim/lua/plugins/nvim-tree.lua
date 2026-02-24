local function copy_to_clipboard(label, value)
  if value == nil or value == "" then
    vim.notify("No " .. label .. " available to copy", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('"', value)
  local ok = pcall(vim.fn.setreg, "+", value)
  if ok then
    vim.notify("Copied " .. label .. ": " .. value)
  else
    vim.notify("Copied " .. label .. " (clipboard provider unavailable)", vim.log.levels.WARN)
  end
end

local function path_values(node)
  local absolute_path = node.absolute_path or node.link_to or ""
  if absolute_path == "" then
    return "", "", ""
  end

  local relative_path = vim.fn.fnamemodify(absolute_path, ":.")
  local file_name = vim.fn.fnamemodify(absolute_path, ":t")
  return absolute_path, relative_path, file_name
end

local function attach_custom_mappings(bufnr)
  local api = require("nvim-tree.api")

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  if api.map and api.map.on_attach and api.map.on_attach.default then
    api.map.on_attach.default(bufnr)
  elseif api.config and api.config.mappings and api.config.mappings.default_on_attach then
    api.config.mappings.default_on_attach(bufnr)
  end

  local function copy_node_path(kind)
    local node = api.tree.get_node_under_cursor()
    if not node then
      vim.notify("No node under cursor", vim.log.levels.WARN)
      return
    end

    local absolute_path, relative_path, file_name = path_values(node)
    if kind == "absolute" then
      copy_to_clipboard("absolute path", absolute_path)
    elseif kind == "relative" then
      copy_to_clipboard("relative path", relative_path)
    else
      copy_to_clipboard("file name", file_name)
    end
  end

  local function show_path_menu()
    local mouse = vim.fn.getmousepos()
    if mouse and mouse.winid == vim.api.nvim_get_current_win() and mouse.line and mouse.line > 0 then
      local col = 0
      if mouse.column and mouse.column > 0 then
        col = mouse.column - 1
      end
      pcall(vim.api.nvim_win_set_cursor, mouse.winid, { mouse.line, col })
    end
    local node = api.tree.get_node_under_cursor()
    if not node then
      vim.notify("No node under cursor", vim.log.levels.WARN)
      return
    end

    local absolute_path, relative_path, file_name = path_values(node)
    local choices = {
      { label = "Copy absolute path", value = absolute_path },
      { label = "Copy relative path", value = relative_path },
      { label = "Copy file name", value = file_name },
    }

    vim.ui.select(choices, {
      prompt = "nvim-tree actions",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end
      copy_to_clipboard(choice.label:lower(), choice.value)
    end)
  end

  vim.keymap.set("n", "gy", function()
    copy_node_path("absolute")
  end, opts("Copy absolute path"))
  vim.keymap.set("n", "Y", function()
    copy_node_path("relative")
  end, opts("Copy relative path"))
  vim.keymap.set("n", "y", function()
    copy_node_path("name")
  end, opts("Copy file name"))
  vim.keymap.set("n", "<RightMouse>", show_path_menu, opts("Open copy-path menu"))
  vim.keymap.set("n", "<2-RightMouse>", show_path_menu, opts("Open copy-path menu"))
end

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      on_attach = attach_custom_mappings,
      view = {
        side = "left",
        width = 36,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
      update_focused_file = {
        enable = true,
      },
    })

    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    vim.keymap.set("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer (VS Code style)" })
  end,
}
