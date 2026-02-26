return {
  "benlubas/molten-nvim",
  dependencies = {
    "3rd/image.nvim",
  },
  build = ":UpdateRemotePlugins",
  lazy = false,
  init = function()
    vim.g.molten_auto_open_output = true
    vim.g.molten_wrap_output = true
    vim.g.molten_virt_text_output = true
    vim.g.molten_image_provider = "image.nvim"
    vim.g.molten_image_location = "both"
    -- Never auto-create kernels from evaluate/export/import commands.
    vim.g.molten_auto_init_behavior = "raise"
  end,
  config = function()
    local ok, remove_comments = pcall(require, "remove_comments")
    if not ok or type(remove_comments) ~= "table" then
      return
    end
    if type(remove_comments.remove_comments) ~= "function" then
      return
    end
    if remove_comments._nvlean_safe_patch then
      return
    end

    local original = remove_comments.remove_comments
    remove_comments.remove_comments = function(str, lang)
      local wrapped_ok, cleaned = pcall(original, str, lang)
      if wrapped_ok and type(cleaned) == "string" then
        return cleaned
      end
      return str
    end
    remove_comments._nvlean_safe_patch = true
  end,
}
