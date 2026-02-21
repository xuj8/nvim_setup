return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          width = 0.95,
          height = 0.9,
        },
        sorting_strategy = "ascending",
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

    vim.keymap.set("n", "<C-p>", find_files, { desc = "Find files (VS Code style)" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search in files" })
  end,
}
