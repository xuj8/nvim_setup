return {
  "3rd/image.nvim",
  build = false,
  opts = function()
    local backend = vim.env.NVIM_IMAGE_BACKEND
    if backend == nil or backend == "" then
      if vim.env.KITTY_PID or vim.env.KITTY_WINDOW_ID then
        backend = "kitty"
      elseif string.find(vim.env.TERM or "", "kitty", 1, true) then
        backend = "kitty"
      elseif vim.fn.executable("ueberzug") == 1 then
        backend = "ueberzug"
      else
        -- Won't be used when plugin is disabled; keeps opts structurally valid.
        backend = "kitty"
      end
    end

    return {
      backend = backend,
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = false,
        },
        neorg = {
          enabled = false,
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },
      max_width = 100,
      max_height = 18,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      tmux_show_only_in_active_window = true,
    }
  end,
}
