---@module 'pdfport.integrations'
---@brief Unified file-tree integration for pdfport.nvim.
---@description
--- Asks `lib.nvim.explorer` which file-tree owns the current buffer and which path is under the cursor.
--- Each individual integration can also be used directly.
---
--- Supported trees:
---   neo-tree  → pdfport.integrations.neotree
---   nvim-tree → pdfport.integrations.nvim_tree
---   netrw     → pdfport.integrations.netrw
---   oil.nvim  → pdfport.integrations.oil

local M = {}

local notify = require("pdfport.util.notify").create("[pdfport.integrations]")

---@return string|nil pdf_path  nil when the cursor is not on a PDF
function M.current_pdf_path()
  return require("lib.nvim.explorer").current_path()
end

---@param opts? PdfPort.OpenOpts  optional extra opts (mode, split, backend_id…)
---@return nil
function M.open_current(opts)
  local path = M.current_pdf_path()
  if not path then
    notify.warn("cursor is not on a PDF (or unsupported file-tree)")
    return
  end
  if not path:lower():match("%.pdf$") then
    notify.warn("not a PDF: " .. path)
    return
  end

  local merged = vim.tbl_deep_extend("force", {
    path = path,
    mode = "buffer",
    split = "vsplit",
    focus = true,
  }, opts or {})

  require("pdfport").open(merged)
end

return M
