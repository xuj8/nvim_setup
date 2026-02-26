return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    styles = {
      sidebars = "normal",
      floats = "normal",
    },
    on_colors = function(colors)
      colors.bg = "#000000"
      colors.bg_dark = "#000000"
      colors.bg_dark1 = "#000000"
      colors.bg_float = "#000000"
      colors.bg_popup = "#000000"
      colors.bg_sidebar = "#000000"
      colors.bg_statusline = "#000000"
      colors.bg_highlight = "#121212"
      colors.bg_visual = "#0F2A4A"
      colors.bg_search = "#1D4ED8"
      colors.border = "#303030"

      colors.fg = "#FFFFFF"
      colors.fg_dark = "#D7D7D7"
      colors.fg_gutter = "#8A8A8A"
      colors.comment = "#7A7A7A"

      colors.blue = "#3B82F6"
      colors.blue0 = "#2563EB"
      colors.blue1 = "#38BDF8"
      colors.blue2 = "#0EA5E9"
      colors.blue5 = "#60A5FA"
      colors.blue6 = "#93C5FD"
      colors.blue7 = "#1D4ED8"

      colors.green = "#22C55E"
      colors.green1 = "#10B981"
      colors.green2 = "#14B8A6"

      colors.yellow = "#FACC15"
      colors.orange = "#F59E0B"

      colors.red = "#EF4444"
      colors.red1 = "#DC2626"

      colors.magenta = "#D946EF"
      colors.magenta2 = "#C026D3"
      colors.purple = "#A855F7"

      colors.cyan = "#06B6D4"
      colors.teal = "#14B8A6"
    end,
    on_highlights = function(hl, c)
      hl.Normal = { fg = "#FFFFFF", bg = "#000000" }
      hl.NormalNC = { fg = "#FFFFFF", bg = "#000000" }
      hl.WinSeparator = { fg = "#5A5A5A", bg = "#000000", bold = true }
      hl.VertSplit = { fg = "#5A5A5A", bg = "#000000", bold = true }
      hl.NvimTreeWinSeparator = { fg = "#5A5A5A", bg = "#000000", bold = true }
      hl.CursorLine = { bg = "#111111" }
      hl.ColorColumn = { bg = "#0E0E0E" }
      hl.Visual = { bg = "#1A294A" }
      hl.NormalFloat = { bg = "#000000" }
      hl.SignColumn = { bg = "#000000" }
      hl.TabLineFill = { bg = "#000000" }
      hl.LineNr = { fg = "#666666" }
      hl.CursorLineNr = { fg = c.yellow, bold = true }
      hl.Comment = { fg = c.comment, italic = false }

      hl.Function = { fg = c.blue, bold = true }
      hl.String = { fg = c.green }
      hl.Constant = { fg = c.yellow }
      hl.Keyword = { fg = c.red, bold = true }
      hl.Statement = { fg = c.red, bold = true }
      hl.Type = { fg = c.cyan, bold = true }

      hl["@function"] = { fg = c.blue, bold = true }
      hl["@string"] = { fg = c.green }
      hl["@constant"] = { fg = c.yellow }
      hl["@keyword"] = { fg = c.red, bold = true }
      hl["@type"] = { fg = c.cyan, bold = true }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
