---@module 'pdfport.renderers._window'
---@brief Window helpers shared by the renderers that open their own window.
---@description
--- `buffer` shows a scratch buffer in a split/tab/the current window, `terminal` runs a display job
--- in a fresh split; both need the same three steps: open a window for a layout, give focus back
--- to where the user was, and close a window only if it still exists. The float renderer opens its
--- window through `lib.nvim.window.make_scratch` and does not use this module.

local api = vim.api

local M = {}

---@alias PdfPort.WindowLayout "current"|"split"|"vsplit"|"tab"|"new"

--- Open a window for `layout` and make it current. `current` reuses the current window; `new` is
--- an empty split below (`:new`), for a terminal job to fill. With `bufnr` the window shows it.
---@param layout PdfPort.WindowLayout
---@param bufnr? integer
---@return integer win
function M.open(layout, bufnr)
  if layout == "tab" then
    vim.cmd("tabnew")
  elseif layout == "split" then
    vim.cmd("split")
  elseif layout == "vsplit" then
    vim.cmd("vsplit")
  elseif layout == "new" then
    vim.cmd("new")
  end
  local win = api.nvim_get_current_win()
  if bufnr then api.nvim_win_set_buf(win, bufnr) end
  return win
end

--- Give focus back to `win` (where the user was) or, when it is gone, to the previous window.
---@param win? integer
---@return nil
function M.restore_focus(win)
  if win and win ~= 0 and api.nvim_win_is_valid(win) then
    api.nvim_set_current_win(win)
  else
    vim.cmd("wincmd p")
  end
end

--- Close `win` if it still exists and is not `keep` (the window to leave alone, usually the one the
--- user started in). Returns whether a window was closed.
---@param win? integer
---@param keep? integer
---@return boolean
function M.close(win, keep)
  if not win or win == keep or not api.nvim_win_is_valid(win) then return false end
  return pcall(api.nvim_win_close, win, true)
end

return M
