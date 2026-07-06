local MiniTest = _G.MiniTest
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        package.loaded["presenting"] = nil
        _G.treesitter_start_calls = {}
        vim.treesitter.start = function(buf, parser)
          table.insert(_G.treesitter_start_calls, { buf = buf, parser = parser })
        end
      ]])
    end,
    post_once = function() child.stop() end,
  },
})

T["syntax_highlighting"] = MiniTest.new_set()

T["syntax_highlighting"]["starts treesitter for slide buffer when enabled"] = function()
  child.lua([[
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "# Slide",
      "",
      "```lua",
      "local answer = 42",
      "```",
    })
    vim.bo.filetype = "markdown"

    require("presenting").setup({
      syntax_highlighting = {
        enabled = true,
        parser = "markdown",
      },
    })

    vim.cmd("Presenting")
  ]])

  MiniTest.expect.equality(child.lua_get("#_G.treesitter_start_calls"), 1)
  MiniTest.expect.equality(child.lua_get("_G.treesitter_start_calls[1].parser"), "markdown")
end

return T
