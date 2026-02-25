return {
  "nanozuki/tabby.nvim",
  event = "VeryLazy",
  config = function()
    local tabline = require("tabby.tabline")
    local molten_spinner = require("config.molten_spinner")

    molten_spinner.setup()

    _G.NvLeanTabNewClick = function(_, clicks, button, modifiers)
      local mods = (modifiers or ""):gsub("%s+", "")
      if clicks == 1 and button == "l" and mods == "" then
        vim.cmd("tabnew")
      end
    end

    tabline.set(function(line)
      return {
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and "TabLineSel" or "TabLine"
          return {
            " ",
            tab.number(),
            ":",
            tab.name(),
            tab.close_btn(" x "),
            " ",
            hl = hl,
            margin = " ",
          }
        end),
        line.spacer(),
        {
          function()
            return molten_spinner.status_text()
          end,
          hl = "TabLineSel",
        },
        {
          "%@v:lua.NvLeanTabNewClick@",
          " + ",
          "%X",
          hl = "TabLine",
        },
        hl = "TabLineFill",
      }
    end)
  end,
}
