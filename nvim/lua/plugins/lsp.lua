local function has_cmd(cmd)
  return vim.fn.executable(cmd) == 1
end

local function pick_python_server()
  if has_cmd("basedpyright-langserver") then
    return "basedpyright"
  end
  if has_cmd("pyright-langserver") then
    return "pyright"
  end
  if has_cmd("pylsp") then
    return "pylsp"
  end
  return nil
end

local function preferred_python_server_for_install()
  local installed = pick_python_server()
  if installed ~= nil then
    return installed
  end

  if has_cmd("node") and has_cmd("npm") then
    return "pyright"
  end

  if has_cmd("python3") then
    return "pylsp"
  end

  return nil
end

local function python_lsp_settings(server)
  if server == "basedpyright" then
    return {
      basedpyright = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
    }
  end

  if server == "pyright" then
    return {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
    }
  end

  return {}
end

local function configure_server(server, opts)
  opts = opts or {}

  if vim.lsp.config ~= nil and vim.lsp.enable ~= nil then
    vim.lsp.config(server, opts)
    vim.lsp.enable(server)
    return
  end

  local lspconfig = require("lspconfig")
  lspconfig[server].setup(opts)
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      PATH = "prepend",
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = function()
      local py_server = preferred_python_server_for_install()
      local ensure = { "clangd" }

      if py_server ~= nil then
        table.insert(ensure, py_server)
      end

      return {
        ensure_installed = ensure,
        automatic_enable = false,
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("nvim-lean-lsp", { clear = true }),
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
          end

          local definitions_picker = function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
              builtin.lsp_definitions()
              return
            end
            vim.lsp.buf.definition()
          end

          local switch_source_header = function()
            if vim.fn.exists(":ClangdSwitchSourceHeader") == 2 then
              vim.cmd("ClangdSwitchSourceHeader")
              return
            end
            vim.notify("Clangd source/header switch is not available in this buffer", vim.log.levels.WARN)
          end

          map("gd", vim.lsp.buf.definition, "LSP: Go to definition")
          map("gD", vim.lsp.buf.declaration, "LSP: Go to declaration")
          map("gI", vim.lsp.buf.implementation, "LSP: Go to implementation")
          map("gR", vim.lsp.buf.references, "LSP: References")
          map("<leader>sd", definitions_picker, "LSP: Definitions picker")
          map("<leader>cs", switch_source_header, "C/C++: Switch source/header")
          map("K", vim.lsp.buf.hover, "LSP: Hover")
          map("<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
          map("<leader>fd", vim.diagnostic.open_float, "Diagnostics: Line")
          map("[d", vim.diagnostic.goto_prev, "Diagnostics: Previous")
          map("]d", vim.diagnostic.goto_next, "Diagnostics: Next")
        end,
      })

      configure_server("clangd", {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
      })

      local py_server = pick_python_server()
      if py_server ~= nil then
        configure_server(py_server, {
          settings = python_lsp_settings(py_server),
        })
      else
        vim.schedule(function()
          vim.notify(
            "Python LSP not configured: install pyright/basedpyright/pylsp so the language server executable is available.",
            vim.log.levels.WARN
          )
        end)
      end
    end,
  },
}
