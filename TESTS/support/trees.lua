-- TESTS/support/trees.lua -- helpers of the file-tree test sheets (TESTS/sheets/*.sheet.lua).
--
-- Loaded INSIDE the child editor of a sheet (`dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")`):
-- sheets are data and cannot require anything while they are read. Finds the real tree plugins on the
-- machine (the suite itself replaces them everywhere; only a sheet wants the real ones) and sets up a
-- two-window project: an editor window with a.txt, ready for a sidebar.

local T = {}

---Directories that may hold a plugin checkout, in order.
---@return string[]
local function search_dirs()
  local dirs = {}
  local function add(d)
    if d and d ~= "" then dirs[#dirs + 1] = vim.fs.normalize(d) end
  end
  add(vim.env.PDFPORT_PLUGINS_DIR)
  local cwd = vim.fn.getcwd()
  add(cwd .. "/.deps")
  add(vim.fs.dirname(cwd))
  -- the child's own stdpath is a sandbox, so look where a plugin manager of the real user installs
  add(vim.env.LOCALAPPDATA and (vim.env.LOCALAPPDATA .. "/nvim-data/lazy"))
  add(vim.env.HOME and (vim.env.HOME .. "/.local/share/nvim/lazy"))
  return dirs
end

---Where the plugin `name` (a directory name such as `neo-tree.nvim`) is installed, or nil.
---@param name string
---@return string|nil
function T.find(name)
  for _, d in ipairs(search_dirs()) do
    if
      vim.fn.isdirectory(d .. "/" .. name .. "/lua") == 1
      or vim.fn.isdirectory(d .. "/" .. name .. "/plugin") == 1
    then
      return d .. "/" .. name
    end
  end
  return nil
end

---Is every named plugin installed?
---@param names string[]
---@return boolean
function T.have(names)
  for _, n in ipairs(names) do
    if not T.find(n) then return false end
  end
  return true
end

---Put the named plugins on the runtimepath (the ones that are not installed are left out).
---@param names string[]
function T.use(names)
  -- the sandboxed stdpath('data') of the child does not exist yet; neo-tree warns about its log file there,
  -- and a multi-line warning waits for <Enter> on an attached UI (which blocks the RPC call)
  vim.fn.mkdir(vim.fn.stdpath("data"), "p")
  for _, n in ipairs(names) do
    local dir = T.find(n)
    if dir then vim.opt.rtp:append(dir) end
  end
end

---A project directory with a.txt open in the one editor window; no intro message, no status line.
---@return string root
function T.project()
  vim.opt.shortmess:append("I")
  vim.o.laststatus = 0
  local root = vim.fs.normalize(vim.fn.tempname())
  vim.fn.mkdir(root, "p")
  vim.fn.writefile({ "alpha" }, root .. "/a.txt")
  vim.fn.writefile({ "beta" }, root .. "/b.txt")
  -- no :cd, the sheets load this file by a path relative to the start directory
  vim.cmd.edit(vim.fn.fnameescape(root .. "/a.txt"))
  _G.trees, _G.sheet_root = T, root
  _G.editor_win = vim.api.nvim_get_current_win()
  return root
end

---Hand a result to pdfport's buffer renderer, as `:PdfPort` does after an extraction.
function T.render()
  require("pdfport.renderers.buffer").render(
    { text = "hello from the pdf", backend = "sheet", format = "text" },
    { path = "doc.pdf" }
  )
end

---Filetype of the buffer of every window of the tab, keyed by window.
---@return table<integer, string>
function T.filetypes()
  local out = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    out[w] = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
  end
  return out
end

---Is a window of the tab showing a buffer of this filetype?
---@param ft string
---@return boolean
function T.shows(ft)
  for _, f in pairs(T.filetypes()) do
    if f == ft then return true end
  end
  return false
end

---Does the current window show the pdfport result buffer?
---@return boolean
function T.on_result()
  return vim.api.nvim_buf_get_name(0):find("pdfport://doc", 1, true) ~= nil
end

return T
