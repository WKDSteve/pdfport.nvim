---@module 'pdfport.renderers.buffer'
---@brief Renders extracted PDF text into a Neovim scratch buffer.
---@description
--- Split behaviour is controlled by opts.split:
---   nil / "current" : replace the current editor window (default)
---   "vsplit"        : open to the right
---   "split"         : open below
---   "tab"           : open in a new tab

local M = {}

local api = vim.api

---@internal
---@param path string
---@return string
local function buf_name(path)
  return string.format("pdfport://%s", vim.fn.fnamemodify(path, ":t:r"))
end

---@internal
---@param name string
---@return integer bufnr
local function get_or_create_buf(name)
  for _, nr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(nr) and api.nvim_buf_get_name(nr) == name then return nr end
  end
  local nr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(nr, name)
  return nr
end

---@internal
---@param line string
---@return string
local function strip_cr(line)
  return (line:gsub("\r$", ""))
end

---@internal
--- Is `buf` a file-tree sidebar? Asks `lib.nvim.explorer` (the one registry of
--- trees) instead of listing filetypes here, so a registered tree needs no change
--- in this plugin. oil is an explorer too, but it edits a directory in an ordinary
--- window and is not a sidebar to move away from.
---@param buf integer
---@return boolean
local function is_sidebar_buf(buf)
  local name = require("lib.nvim.explorer").current(buf)
  return name ~= nil and name ~= "oil"
end

---@internal
---@return integer  orig_win (0 = no switch needed)
local function ensure_editor_win()
  local cur_win = api.nvim_get_current_win()
  local cur_buf = api.nvim_win_get_buf(cur_win)
  local cur_cfg = api.nvim_win_get_config(cur_win)

  local is_sidebar = is_sidebar_buf(cur_buf)
  local is_float = cur_cfg.relative ~= ""
  if not is_sidebar and not is_float then return 0 end

  local wins = api.nvim_tabpage_list_wins(0)
  for i = #wins, 1, -1 do
    local w = wins[i]
    if w ~= cur_win and api.nvim_win_is_valid(w) then
      local wbuf = api.nvim_win_get_buf(w)
      local wcfg = api.nvim_win_get_config(w)
      if wcfg.relative == "" and not is_sidebar_buf(wbuf) then
        api.nvim_set_current_win(w)
        return cur_win
      end
    end
  end
  return 0
end

---@param result PdfPort.Result
---@param opts   PdfPort.OpenOpts
---@return nil
function M.render(result, opts)
  local path = opts.path or ""
  local name = buf_name(path)
  local bufnr = get_or_create_buf(name)

  local split = opts.split
  if not split or split == "current" or split == "" then split = "current" end

  local focus = opts.focus ~= false
  local ft = (result.format == "markdown") and "markdown" or "text"

  local raw_lines = vim.split(result.text or "", "\n", { plain = true })
  local lines = { [#raw_lines] = "" }
  for i = 1, #raw_lines do
    lines[i] = strip_cr(raw_lines[i])
  end

  vim.bo[bufnr].modifiable = true
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local header = strip_cr(
    string.format(
      "<!-- pdfport: %s | backend: %s | format: %s -->",
      vim.fn.fnamemodify(path, ":t"),
      result.backend,
      result.format
    )
  )
  api.nvim_buf_set_lines(bufnr, 0, 0, false, { header, "" })

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].filetype = ft
  vim.bo[bufnr].swapfile = false

  local orig_win = ensure_editor_win()

  if split == "tab" then
    vim.cmd("tabnew")
    api.nvim_win_set_buf(api.nvim_get_current_win(), bufnr)
  elseif split == "split" then
    vim.cmd("split")
    api.nvim_win_set_buf(api.nvim_get_current_win(), bufnr)
  elseif split == "vsplit" then
    vim.cmd("vsplit")
    api.nvim_win_set_buf(api.nvim_get_current_win(), bufnr)
  else
    api.nvim_win_set_buf(api.nvim_get_current_win(), bufnr)
  end

  if not focus then
    if orig_win ~= 0 and api.nvim_win_is_valid(orig_win) then
      api.nvim_set_current_win(orig_win)
    else
      vim.cmd("wincmd p")
    end
  end
end

return M
