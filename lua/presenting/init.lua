--- *presenting.nvim*
--- *Presenting*
---
--- MIT License Copyright (c) 2024 Stefan Otte
---
--- ==============================================================================
---
--- Present your markdown, org-mode, or asciidoc files in a nice way,
--- i.e. directly in nvim.

-- Module definition ==========================================================
local Presenting = {}
local H = {}
Presenting._state = nil

--- Module setup
---
---@param config table|nil
---@usage `require('presenting').setup({})`
Presenting.setup = function(config)
  _G.Presenting = Presenting
  config = H.setup_config(config)
  H.apply_config(config)

  vim.api.nvim_create_user_command("Presenting", Presenting.toggle, {})
  vim.api.nvim_create_user_command("PresentingDevMode", Presenting.dev_mode, {})

  local presenting_autocmd_group_id = vim.api.nvim_create_augroup("PresentingAutoGroup", {})
  vim.api.nvim_create_autocmd("WinResized", {
    group = presenting_autocmd_group_id,
    callback = function() Presenting.resize() end,
  })
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Presenting.config = {
  options = {
    -- The width of the slide buffer.
    width = 60,
  },
  separator = {
    -- Separators for different filetypes.
    -- You can add your own or oberwrite existing ones.
    -- Note: separators are lua patterns, not regexes.
    markdown = "^#+ ",
    org = "^*+ ",
    adoc = "^==+ ",
    asciidoctor = "^==+ ",
  },
  keymaps = {
    -- These are local mappings for the open slide buffer.
    -- Disable existing keymaps by setting them to `nil`.
    -- Add your own keymaps as you desire.
    ["n"] = function() Presenting.next() end,
    ["p"] = function() Presenting.prev() end,
    ["q"] = function() Presenting.quit() end,
    ["f"] = function() Presenting.first() end,
    ["l"] = function() Presenting.last() end,
    ["<CR>"] = function() Presenting.next() end,
    ["<BS>"] = function() Presenting.prev() end,
  },
  -- A function that configures the slide buffer.
  -- If you want custom settings write your own function that accepts a buffer id as argument.
  configure_slide_buffer = function(buf) H.configure_slide_buffer(buf) end,
}
--minidoc_afterlines_end

--- ==============================================================================
--- # Core functionality

--- Toggle presenting mode on/off for the current buffer.
---@param separator string|nil
Presenting.toggle = function(separator)
  if H.in_presenting_mode() then
    Presenting.quit()
  else
    Presenting.start(separator)
  end
end

--- Start presenting the current buffer.
---@param separator string|nil Overwrite the default separator if specified.
Presenting.start = function(separator)
  if H.in_presenting_mode() then
    vim.notify("Already presenting")
    return
  end

  if type(separator) == "table" then
    -- FIXME: why is separator a table when I don't pass anything?
    -- into nil. I don't know why I get a table here when I don't pass anything.
    -- print(vim.inspect(separator))
    -- Workaround: turn not passed separator
    separator = nil
  end

  local filetype = vim.bo.filetype
  separator = separator or Presenting.config.separator[filetype]

  if separator == nil then
    vim.notify(
      "presenting.nvim does not support filetype "
        .. filetype
        .. ". You can specify a separator manually: Presenting.start('---')"
    )
    return
  end

  Presenting._state = {
    filetype = filetype,
    slides = {},
    slide = 1,
    n_slides = nil,
    slide_buf = nil,
    slide_win = nil,
    background_buf = nil,
    background_win = nil,
    footer_buf = nil,
    footer_win = nil,
    view = nil,
  }

  -- content of slides
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  Presenting._state.slides = H.parse_slides(lines, separator)
  Presenting._state.n_slides = #Presenting._state.slides

  H.create_slide_view(Presenting._state)
end

--- Quit the current presentation and go back to the normal buffer.
--- By default this is mapped to `q`.
Presenting.quit = function()
  if not H.in_presenting_mode() then
    vim.notify("Not in presenting mode")
    return
  end

  vim.api.nvim_buf_delete(Presenting._state.slide_buf, { force = true })
  -- vim.api.nvim_win_close(Presenting._state.slide_win, true)

  vim.api.nvim_buf_delete(Presenting._state.footer_buf, { force = true })
  -- vim.api.nvim_win_close(Presenting._state.footer_win, true)

  vim.api.nvim_buf_delete(Presenting._state.background_buf, { force = true })
  -- vim.api.nvim_win_close(Presenting._state.background_win, true)

  Presenting._state = nil
end

--- Go to the next slide.
--- By default this is mapped to `<CR>` and `n`.
Presenting.next = function()
  if not H.in_presenting_mode() then
    vim.notify("Not presenting. Call `PresentingStart` first.")
    return
  end
  H.set_slide_content(
    Presenting._state,
    math.min(Presenting._state.slide + 1, Presenting._state.n_slides)
  )
end

--- Go to the previous slide.
--- By default this is mapped to `<BS>` and `p`.
Presenting.prev = function()
  if not H.in_presenting_mode() then
    vim.notify("Not presenting. Call `PresentingStart` first.")
    return
  end
  H.set_slide_content(Presenting._state, math.max(Presenting._state.slide - 1, 1))
end

--- Go to the first slide.
--- By default this is mapped to `f`.
Presenting.first = function()
  if not H.in_presenting_mode() then
    vim.notify("Not presenting. Call `PresentingStart` first.")
    return
  end
  H.set_slide_content(Presenting._state, 1)
end

--- Go to the last slide.
--- By default this is mapped to `l`.
Presenting.last = function()
  if not H.in_presenting_mode() then
    vim.notify("Not presenting. Call `PresentingStart` first.")
    return
  end
  H.set_slide_content(Presenting._state, Presenting._state.n_slides)
end

---Resize the slide window.
Presenting.resize = function()
  if not H.in_presenting_mode() then return end
  if
    (Presenting._state.background_win == nil)
    or (Presenting._state.slide_win == nil)
    or (Presenting._state.footer_win == nil)
  then
    return
  end

  local window_config = H.get_win_configs()
  vim.api.nvim_win_set_config(Presenting._state.background_win, window_config.background)
  vim.api.nvim_win_set_config(Presenting._state.footer_win, window_config.footer)
  vim.api.nvim_win_set_config(Presenting._state.slide_win, window_config.slide)
end

Presenting.dev_mode = function()
  package.loaded["presenting"] = nil
  _G.Presenting = nil
  require("presenting").start()
end

--- ==============================================================================
--- Internal Helper
--- As end user you should not need to use these functions.
---@private
H.default_config = vim.deepcopy(Presenting.config)

---@param config table|nil
---@private
H.setup_config = function(config)
  vim.validate({ config = { config, "table", true } })
  -- TODO: validate some more
  return vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})
end

---@param config table
---@private
H.apply_config = function(config)
  -- nothing to do right now
  Presenting.config = config
end

---@return table
---@private
H.get_win_configs = function()
  local slide_width = Presenting.config.options.width
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  local offset = math.ceil((width - slide_width) / 2)
  return {
    background = {
      style = "minimal",
      relative = "editor",
      focusable = false,
      width = width,
      height = height,
      row = 0,
      col = 0,
      zindex = 1,
    },
    slide = {
      style = "minimal",
      relative = "editor",
      width = slide_width,
      height = height - 5,
      row = 0,
      col = offset,
      zindex = 10,
    },
    footer = {
      style = "minimal",
      relative = "editor",
      width = slide_width,
      height = 1,
      row = height - 1,
      col = offset,
      focusable = false,
      zindex = 2,
    },
  }
end

---@param state table
---@private
H.create_slide_view = function(state)
  local window_config = H.get_win_configs()

  state.background_buf = vim.api.nvim_create_buf(false, true)
  state.background_win =
    vim.api.nvim_open_win(state.background_buf, false, window_config.background)

  -- TODO: maybe just use vims statusline instead of my custom footer :)
  state.footer_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.footer_buf, 0, -1, false, { "presenting.nvim" })
  state.footer_win = vim.api.nvim_open_win(state.footer_buf, false, window_config.footer)

  state.slide_buf = vim.api.nvim_create_buf(false, true)
  state.slide_win = vim.api.nvim_open_win(state.slide_buf, true, window_config.slide)
  Presenting.config.configure_slide_buffer(state.slide_buf)
  H.set_slide_keymaps(state.slide_buf, Presenting.config.keymaps)

  H.set_slide_content(state, 1)
end

---@param lines table
---@param separator string
---@return table
---@private
H.parse_slides = function(lines, separator)
  -- TODO: isn't there a split() in lua that keeps the separator?
  local slides = {}
  local slide = {}
  for _, line in pairs(lines) do
    if line:match(separator) then
      if #slide > 0 then table.insert(slides, table.concat(slide, "\n")) end
      slide = {}
    end
    table.insert(slide, line)
  end
  table.insert(slides, table.concat(slide, "\n"))

  return slides
end

---@param buf integer
---@private
H.configure_slide_buffer = function(buf)
  -- TODO: make this configurable via config
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", Presenting._state.filetype)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

---@param state table
---@param slide integer
---@private
H.set_slide_content = function(state, slide)
  local orig_modifiable = vim.api.nvim_buf_get_option(state.slide_buf, "modifiable")
  vim.api.nvim_buf_set_option(state.slide_buf, "modifiable", true)
  state.slide = slide
  vim.api.nvim_buf_set_lines(
    state.slide_buf,
    0,
    -1,
    false,
    vim.split(state.slides[state.slide], "\n")
  )
  vim.api.nvim_buf_set_option(state.slide_buf, "modifiable", orig_modifiable)

  -- create slide numbers for footer
  local footer_nrs = state.slide .. "/" .. state.n_slides

  -- extract title from first line of first slide
  local presentation_title = vim.split(state.slides[1], "\n")[1]
  -- strip any trailing whitespace
  presentation_title = presentation_title:gsub("%s+$", "")
  -- strip any starting * or # for org and md
  presentation_title = presentation_title:gsub("^%*+%s*", "")
  presentation_title = presentation_title:gsub("^#+%s*", "")

  -- if title is too long shorten with elipsis
  local width = Presenting.config.options.width
  if #presentation_title > width - #footer_nrs - 3 then
    presentation_title = presentation_title:sub(1, width - #footer_nrs - 3) .. "..."
  end
  -- add white spaces between title and slide number
  local white_space_fill = string.rep(" ", width - #presentation_title - #footer_nrs)
  local footer_text = presentation_title .. white_space_fill .. footer_nrs
  vim.api.nvim_buf_set_lines(state.footer_buf, 0, -1, false, { footer_text })
end

---@param buf integer
---@param mappings table
---@private
H.set_slide_keymaps = function(buf, mappings)
  for k, v in pairs(mappings) do
    if type(v) == "string" then
      local cmd = ":lua require('presenting')." .. v .. "()<CR>"
      vim.api.nvim_buf_set_keymap(buf, "n", k, cmd, { noremap = true, silent = true })
    elseif type(v) == "function" then
      vim.api.nvim_buf_set_keymap(buf, "n", k, "", { callback = v, noremap = true, silent = true })
    end
    -- no keymap on nil 🤷
  end
end

---@return boolean
H.in_presenting_mode = function() return Presenting._state ~= nil end

return Presenting
