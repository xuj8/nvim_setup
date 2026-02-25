return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local action_state = require("telescope.actions.state")
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local grep_filters = {
      include = type(vim.g.nvim_lean_live_grep_include_globs) == "string"
          and vim.g.nvim_lean_live_grep_include_globs
        or "",
      exclude = type(vim.g.nvim_lean_live_grep_exclude_globs) == "string"
          and vim.g.nvim_lean_live_grep_exclude_globs
        or "",
    }

    local function paste_system_clipboard()
      local termcodes = vim.api.nvim_replace_termcodes("<C-r>+", true, false, true)
      vim.api.nvim_feedkeys(termcodes, "i", true)
    end

    local function delete_previous_word()
      local termcodes = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
      vim.api.nvim_feedkeys(termcodes, "i", true)
    end

    local function selected_entry_full_path()
      local entry = action_state.get_selected_entry()
      if entry == nil then
        return nil
      end

      local raw = entry.path or entry.filename or entry.value or entry[1]
      if type(raw) ~= "string" or raw == "" then
        return nil
      end

      return vim.fn.fnamemodify(raw, ":p")
    end

    local function show_and_copy_selected_full_path(_)
      local full_path = selected_entry_full_path()
      if full_path == nil then
        vim.notify("No path found for selected result", vim.log.levels.WARN)
        return
      end

      vim.fn.setreg('"', full_path)
      pcall(vim.fn.setreg, "+", full_path)
      vim.notify(full_path)
    end

    local function split_csv_globs(raw)
      local values = {}
      if raw == nil or raw == "" then
        return values
      end

      local function sanitize_glob_token(token)
        local cleaned = vim.trim(token)
        if cleaned == "" then
          return ""
        end

        local first = string.sub(cleaned, 1, 1)
        local last = string.sub(cleaned, -1)
        if (first == "'" and last == "'") or (first == '"' and last == '"') then
          cleaned = string.sub(cleaned, 2, -2)
        end

        cleaned = vim.trim(cleaned)
        return cleaned
      end

      for token in string.gmatch(raw, "([^,]+)") do
        local sanitized = sanitize_glob_token(token)
        if sanitized ~= "" then
          table.insert(values, sanitized)
        end
      end

      return values
    end

    local function append_unique(values, value)
      for _, existing in ipairs(values) do
        if existing == value then
          return
        end
      end
      table.insert(values, value)
    end

    local function normalized_globs(tokens)
      local values = {}
      for _, token in ipairs(tokens) do
        local cleaned = token
        if string.sub(cleaned, 1, 1) == "!" then
          cleaned = string.sub(cleaned, 2)
        end

        if cleaned ~= "" then
          append_unique(values, cleaned)
          if not string.find(cleaned, "/", 1, true) and not string.find(cleaned, "**/", 1, true) then
            append_unique(values, "**/" .. cleaned)
          end
        end
      end

      return values
    end

    local function set_grep_filters(include_raw, exclude_raw)
      grep_filters.include = include_raw or ""
      grep_filters.exclude = exclude_raw or ""
      vim.g.nvim_lean_live_grep_include_globs = grep_filters.include
      vim.g.nvim_lean_live_grep_exclude_globs = grep_filters.exclude
    end

    local function filtered_live_grep(include_raw, exclude_raw)
      local include_globs = normalized_globs(split_csv_globs(include_raw))
      local exclude_globs = normalized_globs(split_csv_globs(exclude_raw))

      builtin.live_grep({
        path_display = { "absolute" },
        wrap_results = true,
        additional_args = function()
          local args = { "--hidden", "--glob", "!.git" }

          for _, include_glob in ipairs(include_globs) do
            table.insert(args, "--glob")
            table.insert(args, include_glob)
          end

          for _, exclude_glob in ipairs(exclude_globs) do
            table.insert(args, "--glob")
            table.insert(args, "!" .. exclude_glob)
          end

          return args
        end,
      })
    end

    local function live_grep_with_filters()
      vim.ui.input({
        prompt = "Include globs (comma-separated, optional): ",
        default = grep_filters.include,
      }, function(include_input)
        if include_input == nil then
          return
        end

        vim.ui.input({
          prompt = "Exclude globs (comma-separated, optional): ",
          default = grep_filters.exclude,
        }, function(exclude_input)
          if exclude_input == nil then
            return
          end

          set_grep_filters(include_input, exclude_input)
          filtered_live_grep(grep_filters.include, grep_filters.exclude)
        end)
      end)
    end

    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          width = 0.99,
          height = 0.9,
        },
        sorting_strategy = "ascending",
        path_display = function(_, path)
          return path
        end,
        mappings = {
          i = {
            ["<C-S-v>"] = paste_system_clipboard,
            ["<D-v>"] = paste_system_clipboard,
            ["<S-Insert>"] = paste_system_clipboard,
            ["<C-y>"] = show_and_copy_selected_full_path,
            ["<C-w>"] = delete_previous_word,
            ["<C-BS>"] = delete_previous_word,
            ["<M-BS>"] = delete_previous_word,
            ["<A-BS>"] = delete_previous_word,
            ["<M-Del>"] = delete_previous_word,
            ["<A-Del>"] = delete_previous_word,
          },
          n = {
            ["<C-y>"] = show_and_copy_selected_full_path,
          },
        },
      },
    })

    local find_files = function()
      local opts = {
        hidden = true,
      }

      if vim.fn.executable("fd") == 1 then
        opts.find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
      elseif vim.fn.executable("fdfind") == 1 then
        opts.find_command = { "fdfind", "--type", "f", "--hidden", "--exclude", ".git" }
      else
        opts.find_command = { "rg", "--files", "--hidden", "-g", "!.git" }
      end

      builtin.find_files(opts)
    end

    local live_grep_project = function()
      filtered_live_grep(grep_filters.include, grep_filters.exclude)
    end

    local clear_live_grep_filters = function()
      set_grep_filters("", "")
      vim.notify("Cleared project search include/exclude filters")
    end

    vim.keymap.set("n", "<C-p>", find_files, { desc = "Find files (VS Code style)" })
    vim.keymap.set("n", "<leader>fg", live_grep_project, { desc = "Search in files" })
    vim.keymap.set("n", "<leader>sf", live_grep_project, { desc = "Project text search (uses saved include/exclude globs)" })
    vim.keymap.set("n", "<leader>sF", live_grep_with_filters, { desc = "Project text search with include/exclude globs" })
    vim.keymap.set("n", "<leader>sR", clear_live_grep_filters, { desc = "Clear project search include/exclude globs" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Search word under cursor in project" })
  end,
}
