return {
  "3rd/image.nvim",
  build = false,
  opts = function()
    local backend = vim.env.NVIM_IMAGE_BACKEND
    if backend == nil or backend == "" then
      backend = "kitty"
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
