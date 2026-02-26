return {
  "quarto-dev/quarto-nvim",
  ft = { "markdown", "quarto" },
  dependencies = {
    "jmbuhr/otter.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    lspFeatures = {
      enabled = false,
    },
    codeRunner = {
      enabled = true,
      default_method = "molten",
    },
  },
}
