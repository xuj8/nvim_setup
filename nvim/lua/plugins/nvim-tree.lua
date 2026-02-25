local function copy_to_clipboard(label, value)
  if value == nil or value == "" then
    vim.notify("No " .. label .. " available to copy", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('"', value)
  local ok = pcall(vim.fn.setreg, "+", value)
  if not ok then
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

local function node_base_dir(node)
  local absolute_path = node.absolute_path or node.link_to or ""
  if absolute_path == "" then
    return ""
  end

  if node.type == "directory" then
    return absolute_path
  end

  return vim.fn.fnamemodify(absolute_path, ":h")
end

local function nvim_tree_icon_config()
  if vim.env.NVIM_NO_NERD_FONT == "1" then
    return {
      show = {
        file = false,
        folder = true,
        folder_arrow = false,
        git = false,
        modified = false,
        diagnostics = false,
        bookmarks = false,
      },
      glyphs = {
        folder = {
          default = "[D]",
          open = "[O]",
          empty = "[D]",
          empty_open = "[O]",
          symlink = "[L]",
          symlink_open = "[L]",
          arrow_open = "v",
          arrow_closed = ">",
        },
      },
    }
  end

  return {
    show = {
      file = true,
      folder = true,
      folder_arrow = true,
      git = true,
      modified = true,
      diagnostics = true,
      bookmarks = true,
    },
  }
end

local function setup_nvim_tree_auto_quit()
  local group = vim.api.nvim_create_augroup("nvim-tree-auto-quit", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    nested = true,
    callback = function()
      if #vim.api.nvim_list_uis() == 0 then
        return
      end

      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins ~= 1 then
        return
      end

      local buf = vim.api.nvim_win_get_buf(wins[1])
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
      if filetype == "NvimTree" then
        vim.cmd("quit")
      end
    end,
  })
end

local function setup_nvim_tree_auto_open()
  local group = vim.api.nvim_create_augroup("nvim-tree-auto-open", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      if #vim.api.nvim_list_uis() == 0 then
        return
      end

      local api = require("nvim-tree.api")
      api.tree.open()

      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins > 1 then
        vim.cmd("wincmd p")
      end
    end,
  })
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

  local function create_directory_under_cursor()
    local node = api.tree.get_node_under_cursor()
    if not node then
      vim.notify("No node under cursor", vim.log.levels.WARN)
      return
    end

    local base_dir = node_base_dir(node)
    if base_dir == "" then
      vim.notify("Unable to determine parent directory", vim.log.levels.WARN)
      return
    end

    vim.ui.input({
      prompt = "New directory name: ",
    }, function(input)
      if input == nil then
        return
      end

      local trimmed = vim.trim(input)
      if trimmed == "" then
        return
      end

      local target_dir = base_dir .. "/" .. trimmed
      local mkdir_result = vim.fn.mkdir(target_dir, "p")
      if mkdir_result == 0 then
        vim.notify("Failed to create directory: " .. target_dir, vim.log.levels.ERROR)
        return
      end

      api.tree.reload()
    end)
  end

  local function rename_node_under_cursor()
    local node = api.tree.get_node_under_cursor()
    if not node then
      vim.notify("No node under cursor", vim.log.levels.WARN)
      return
    end

    local absolute_path = node.absolute_path or node.link_to or ""
    if absolute_path == "" then
      vim.notify("Unable to determine node path", vim.log.levels.WARN)
      return
    end

    local current_name = vim.fn.fnamemodify(absolute_path, ":t")
    local parent_dir = vim.fn.fnamemodify(absolute_path, ":h")

    vim.ui.input({
      prompt = "Rename to: ",
      default = current_name,
    }, function(input)
      if input == nil then
        return
      end

      local trimmed = vim.trim(input)
      if trimmed == "" or trimmed == current_name then
        return
      end

      if string.find(trimmed, "/", 1, true) or string.find(trimmed, "\\", 1, true) then
        vim.notify("Use a single name, not a path", vim.log.levels.WARN)
        return
      end

      local target_path = parent_dir .. "/" .. trimmed
      if vim.loop.fs_stat(target_path) ~= nil then
        vim.notify("Target already exists: " .. target_path, vim.log.levels.ERROR)
        return
      end

      local rename_result = vim.fn.rename(absolute_path, target_path)
      if rename_result ~= 0 then
        vim.notify("Failed to rename: " .. absolute_path, vim.log.levels.ERROR)
        return
      end

      api.tree.reload()
    end)
  end

  local function delete_node_with_confirm(expected_type)
    local node = api.tree.get_node_under_cursor()
    if not node then
      vim.notify("No node under cursor", vim.log.levels.WARN)
      return
    end

    local absolute_path = node.absolute_path or node.link_to or ""
    if absolute_path == "" then
      vim.notify("Unable to determine node path", vim.log.levels.WARN)
      return
    end

    local is_directory = vim.fn.isdirectory(absolute_path) == 1
    if expected_type == "file" and is_directory then
      vim.notify("Selected node is a directory, not a file", vim.log.levels.WARN)
      return
    end
    if expected_type == "directory" and not is_directory then
      vim.notify("Selected node is a file, not a directory", vim.log.levels.WARN)
      return
    end

    local target_label = expected_type
    local first_confirm = vim.fn.confirm(
      "Delete " .. target_label .. "?\n" .. absolute_path,
      "&No\n&Yes",
      1
    )
    if first_confirm ~= 2 then
      return
    end

    local second_confirm = vim.fn.confirm(
      "Final confirmation: permanently delete this " .. target_label .. "?\n" .. absolute_path,
      "&Cancel\n&Delete",
      1
    )
    if second_confirm ~= 2 then
      return
    end

    local delete_result
    if is_directory then
      delete_result = vim.fn.delete(absolute_path, "rf")
    else
      delete_result = vim.fn.delete(absolute_path)
    end

    if delete_result ~= 0 then
      vim.notify("Failed to delete " .. target_label .. ": " .. absolute_path, vim.log.levels.ERROR)
      return
    end

    vim.notify("Deleted " .. target_label .. ": " .. absolute_path)
    api.tree.reload()
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
      { label = "Copy absolute path", kind = "absolute", value = absolute_path },
      { label = "Copy relative path", kind = "relative", value = relative_path },
      { label = "Copy file name", kind = "name", value = file_name },
      { label = "Create directory here", kind = "mkdir", value = "" },
      { label = "Rename", kind = "rename", value = "" },
      { label = "Delete file (with confirm)", kind = "delete_file", value = "" },
      { label = "Delete directory (with confirm)", kind = "delete_directory", value = "" },
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
      if choice.kind == "mkdir" then
        create_directory_under_cursor()
        return
      end
      if choice.kind == "rename" then
        rename_node_under_cursor()
        return
      end
      if choice.kind == "delete_file" then
        delete_node_with_confirm("file")
        return
      end
      if choice.kind == "delete_directory" then
        delete_node_with_confirm("directory")
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
  vim.keymap.set("n", "gD", create_directory_under_cursor, opts("Create directory"))
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
        icons = nvim_tree_icon_config(),
      },
      filters = {
        dotfiles = false,
      },
      update_focused_file = {
        enable = true,
      },
    })

    setup_nvim_tree_auto_quit()
    setup_nvim_tree_auto_open()

    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    vim.keymap.set("n", "<C-b>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer (VS Code style)" })
  end,
}
