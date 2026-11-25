---@module 'pdfport.core.registry'
---@brief Backend, producer, and renderer registry for pdfport.nvim.
---@description
--- Three independent registries: extraction backends, creation producers, and
--- output renderers. Registration is idempotent. All lookups are O(1).

local M = {}

local lib_registry = require("lib.nvim.registry")

---Build the two ordered registries (backends, producers) on `lib.nvim.registry`: one entry per id, in
---first-registration order, a re-registration replaces the entry and keeps its slot.
---@param label string   # "backend" or "producer": prefix of the assert messages
---@param required string # the one method besides `available` that an entry must have
local function entries(label, required)
  local reg = lib_registry.new({ name = label })
  return {
    register = function(entry)
      assert(type(entry) == "table", label .. " must be a table")
      assert(
        type(entry.id) == "string" and entry.id ~= "",
        label .. ".id must be a non-empty string"
      )
      assert(type(entry.available) == "function", label .. ".available must be a function")
      assert(type(entry[required]) == "function", label .. "." .. required .. " must be a function")
      reg:register(entry.id, entry)
    end,
    get = function(id)
      return reg:get(id)
    end,
    all = function()
      return reg:all()
    end,
    ids = function()
      return reg:keys()
    end,
    has = function(id)
      return reg:has(id)
    end,
  }
end

local backends = entries("backend", "extract")
local producers = entries("producer", "create")

---@param backend PdfPort.Backend
---@return nil
function M.register_backend(backend)
  backends.register(backend)
end

---@param id PdfPort.BackendId
---@return PdfPort.Backend|nil
function M.get_backend(id)
  return backends.get(id)
end

---@return PdfPort.Backend[]
function M.all_backends()
  return backends.all()
end

---@return PdfPort.BackendId[]
function M.backend_ids()
  return backends.ids()
end

---@param id PdfPort.BackendId
---@return boolean
function M.has_backend(id)
  return backends.has(id)
end

---@param producer PdfPort.Producer
---@return nil
function M.register_producer(producer)
  producers.register(producer)
end

---@param id PdfPort.ProducerId
---@return PdfPort.Producer|nil
function M.get_producer(id)
  return producers.get(id)
end

---@return PdfPort.Producer[]
function M.all_producers()
  return producers.all()
end

---@return PdfPort.ProducerId[]
function M.producer_ids()
  return producers.ids()
end

---@param id PdfPort.ProducerId
---@return boolean
function M.has_producer(id)
  return producers.has(id)
end

-- #############################################################################
-- Renderer registry
-- #############################################################################

---@type table<PdfPort.RendererMode, fun(result: PdfPort.Result, opts: PdfPort.RenderOpts): nil>
local _renderers = {}

---@param mode PdfPort.RendererMode
---@param fn fun(result: PdfPort.Result, opts: PdfPort.RenderOpts): nil
---@return nil
function M.register_renderer(mode, fn)
  assert(type(mode) == "string" and mode ~= "", "mode must be a non-empty string")
  assert(type(fn) == "function", "renderer fn must be a function")
  _renderers[mode] = fn
end

---@param mode PdfPort.RendererMode
---@return (fun(result: PdfPort.Result, opts: PdfPort.RenderOpts): nil)|nil
function M.get_renderer(mode)
  return _renderers[mode]
end

---@return PdfPort.RendererMode[]
function M.renderer_modes()
  local modes = {}
  for mode in pairs(_renderers) do
    modes[#modes + 1] = mode
  end
  return modes
end

---@return string[]
function M.diagnostics()
  local lines = { "pdfport registry diagnostics", "" }
  lines[#lines + 1] = "Backends:"
  if #backends.ids() == 0 then
    lines[#lines + 1] = "  (none registered)"
  else
    for i, id in ipairs(backends.ids()) do
      local b = backends.get(id)
      local ok, avail = pcall(b.available)
      local status = (ok and avail) and "available" or "unavailable"
      lines[#lines + 1] = string.format("  [%d] %-16s  %s", i, id, status)
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Producers:"
  if #producers.ids() == 0 then
    lines[#lines + 1] = "  (none registered)"
  else
    for i, id in ipairs(producers.ids()) do
      local p = producers.get(id)
      local ok, avail = pcall(p.available)
      local status = (ok and avail) and "available" or "unavailable"
      lines[#lines + 1] = string.format("  [%d] %-16s  %s", i, id, status)
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Renderers:"
  local modes = M.renderer_modes()
  if #modes == 0 then
    lines[#lines + 1] = "  (none registered)"
  else
    for _, mode in ipairs(modes) do
      lines[#lines + 1] = string.format("  %-12s", mode)
    end
  end
  return lines
end

return M
