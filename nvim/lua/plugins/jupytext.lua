return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,
  config = function()
    if vim.g.notebook_auto_import_outputs == nil then
      vim.g.notebook_auto_import_outputs = false
    end

    local function has_molten_command(name)
      return vim.fn.exists(":" .. name) == 2
    end

    local function contains(list, value)
      if type(list) ~= "table" then
        return false
      end
      for _, item in ipairs(list) do
        if item == value then
          return true
        end
      end
      return false
    end

    local function molten_initialized()
      local ok, status = pcall(require, "molten.status")
      if not ok or status == nil or type(status.initialized) ~= "function" then
        return false
      end
      return status.initialized() == "Molten"
    end

    local function notebook_status(message, level)
      local hl = "Normal"
      if level == vim.log.levels.ERROR then
        hl = "ErrorMsg"
      elseif level == vim.log.levels.WARN then
        hl = "WarningMsg"
      end
      vim.api.nvim_echo({ { message, hl } }, false, {})
    end

    local function ipynb_kernel_name(path)
      if type(path) ~= "string" or path == "" then
        return nil
      end

      local file = io.open(path, "r")
      if file == nil then
        return nil
      end

      local raw = file:read("*a")
      file:close()

      if raw == nil or raw == "" then
        return nil
      end

      local ok, decoded = pcall(vim.json.decode, raw)
      if not ok or type(decoded) ~= "table" then
        return nil
      end

      local metadata = decoded.metadata
      if type(metadata) ~= "table" then
        return nil
      end

      local kernelspec = metadata.kernelspec
      if type(kernelspec) ~= "table" then
        return nil
      end

      local name = kernelspec.name
      if type(name) ~= "string" or name == "" then
        return nil
      end

      return name
    end

    local function buffer_running_kernels()
      local ok, kernels = pcall(vim.fn.MoltenRunningKernels, true)
      if not ok or type(kernels) ~= "table" then
        return {}
      end
      return kernels
    end

    local function resolve_buffer_kernel(bufnr, notebook_path)
      local kernels = buffer_running_kernels()
      if #kernels == 0 then
        return nil
      end

      local preferred = vim.b[bufnr].molten_preferred_kernel
      if type(preferred) == "string" and preferred ~= "" and contains(kernels, preferred) then
        return preferred
      end

      local notebook_kernel = ipynb_kernel_name(notebook_path)
      if notebook_kernel ~= nil and contains(kernels, notebook_kernel) then
        vim.b[bufnr].molten_preferred_kernel = notebook_kernel
        return notebook_kernel
      end

      local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
      if type(venv) == "string" and venv ~= "" then
        local fallback_kernel = vim.fn.fnamemodify(venv, ":t")
        if contains(kernels, fallback_kernel) then
          vim.b[bufnr].molten_preferred_kernel = fallback_kernel
          return fallback_kernel
        end
      end

      if #kernels == 1 then
        vim.b[bufnr].molten_preferred_kernel = kernels[1]
        return kernels[1]
      end

      -- Avoid interactive prompts on :w by choosing a deterministic kernel.
      vim.b[bufnr].molten_preferred_kernel = kernels[1]
      return kernels[1]
    end

    local function maybe_auto_import_outputs(event)
      if vim.g.notebook_auto_import_outputs ~= true then
        return
      end
      if not has_molten_command("MoltenImportOutput") then
        return
      end

      local bufnr = event.buf
      if vim.b[bufnr].molten_auto_import_done then
        return
      end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if not molten_initialized() then
          return
        end

        local notebook_path = event.file
        if type(notebook_path) ~= "string" or notebook_path == "" then
          notebook_path = vim.api.nvim_buf_get_name(bufnr)
        end
        if type(notebook_path) ~= "string" or notebook_path == "" then
          return
        end

        local kernel = resolve_buffer_kernel(bufnr, notebook_path)
        if kernel == nil then
          return
        end

        local ok = pcall(vim.cmd, {
          cmd = "MoltenImportOutput",
          args = { notebook_path, kernel },
        })
        if ok then
          vim.b[bufnr].molten_auto_import_done = true
        end
      end)
    end

    local function maybe_auto_export_outputs(event)
      if not has_molten_command("MoltenExportOutput") then
        return
      end

      local bufnr = event.buf
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      if not molten_initialized() then
        notebook_status("Notebook export: skipped (Molten not initialized)", vim.log.levels.WARN)
        return
      end

      local notebook_path = event.file
      if type(notebook_path) ~= "string" or notebook_path == "" then
        notebook_path = vim.api.nvim_buf_get_name(bufnr)
      end
      if type(notebook_path) ~= "string" or notebook_path == "" then
        notebook_status("Notebook export: skipped (no notebook path)", vim.log.levels.WARN)
        return
      end

      local kernel = resolve_buffer_kernel(bufnr, notebook_path)
      if kernel == nil then
        notebook_status("Notebook export: skipped (no active kernel for this buffer)", vim.log.levels.WARN)
        return
      end

      local absolute_notebook_path = vim.fn.fnamemodify(notebook_path, ":p")
      notebook_status(
        ("Notebook export: running (%s, kernel=%s)"):format(absolute_notebook_path, kernel),
        vim.log.levels.INFO
      )

      local ok, err = pcall(vim.cmd, {
        cmd = "MoltenExportOutput",
        bang = true,
        args = { notebook_path, kernel },
      })
      if not ok then
        notebook_status("Notebook export: failed - " .. tostring(err), vim.log.levels.ERROR)
        return
      end

      notebook_status("Notebook export: finished", vim.log.levels.INFO)
    end

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
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
      custom_language_formatting = {},
    })

    local group = vim.api.nvim_create_augroup("NotebookOutputSync", { clear = true })

    vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
      group = group,
      pattern = { "*.ipynb" },
      callback = maybe_auto_import_outputs,
    })

    vim.api.nvim_create_autocmd({ "BufWritePost", "FileWritePost" }, {
      group = group,
      pattern = { "*.ipynb" },
      callback = maybe_auto_export_outputs,
    })
  end,
}
