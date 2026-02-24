return {
  "benlubas/molten-nvim",
  build = ":UpdateRemotePlugins",
  lazy = false,
  init = function()
    vim.g.molten_auto_open_output = true
    vim.g.molten_wrap_output = true
    vim.g.molten_virt_text_output = true
    vim.g.molten_image_provider = "none"
  end,
}
