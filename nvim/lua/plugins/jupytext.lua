return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,
  config = function()
    if vim.fn.executable("jupytext") ~= 1 then
      vim.schedule(function()
        vim.notify(
          "jupytext.nvim disabled: 'jupytext' CLI not found on PATH.",
          vim.log.levels.WARN
        )
      end)
      return
    end

    require("jupytext").setup({
      style = "hydrogen",
      output_extension = "auto",
      force_ft = nil,
      custom_language_formatting = {},
    })
  end,
}
