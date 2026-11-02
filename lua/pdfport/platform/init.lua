---@module 'pdfport.platform'
---@brief OS detection and external tool availability for pdfport.nvim.
---@description
--- Cached runtime checks for OS type and binary availability.
--- All checks are memoized after first evaluation.

local M = {}

-- OS/WSL detection delegates to lib.nvim.cross.platform (uname + env-var +
-- /proc fallback chain — more robust than a single sysname match / a single
-- /proc/version read, and cached internally there too).
local lib_is_windows = require("lib.nvim.cross.platform.is_windows")
local lib_is_macos = require("lib.nvim.cross.platform.is_macos")
local lib_is_linux = require("lib.nvim.cross.platform.is_linux")
local lib_is_wsl = require("lib.nvim.cross.platform.is_wsl")

---@type table<string, boolean>
local _exe_cache = {}

---@return "windows"|"macos"|"linux"|"unknown"
function M.os()
  if lib_is_windows() then return "windows" end
  if lib_is_macos() then return "macos" end
  if lib_is_linux() or lib_is_wsl() then return "linux" end
  return "unknown"
end

---@return boolean
function M.is_wsl()
  return lib_is_wsl()
end

-- has/first_available delegate to lib.nvim.core, which memoizes per binary
-- name internally (this module's own version re-checked vim.fn.executable
-- every call for names not yet in _exe_cache). _exe_cache itself stays —
-- it's still used below for has_python_module's "pymod:<module>" checks,
-- a different kind of probe (spawns `python -c "import module"`).

---@param exe string
---@return boolean
function M.has(exe)
  return require("lib.nvim.core").has_exec(exe)
end

---@param executables string[]
---@return string|nil
function M.first_available(executables)
  return require("lib.nvim.core").first_available(executables)
end

---@type string|nil
local _python_cache = nil
---@type boolean
local _python_resolved = false

---@return string|nil
function M.python()
  if _python_resolved then return _python_cache end
  _python_resolved = true
  _python_cache = M.first_available({ "python3", "python", "py" })
  return _python_cache
end

-- Upper bound for one `python -c "import X"` probe. A timeout counts as "module
-- not available" (and is cached as such): a heavy import that needs longer than
-- this is not something the backend chain should wait for.
local PROBE_TIMEOUT_MS = 5000

---@type integer  # bumped by reset_cache() so a probe finishing afterwards cannot refill the cache
local _probe_generation = 0
---@type table<string, fun(ok: boolean)[]>
local _probe_waiting = {}

---@param module string
---@return string[]
local function probe_argv(module)
  return { M.python() --[[@as string]], "-c", "import " .. module }
end

---@param res vim.SystemCompleted|nil
---@return boolean  # true once the interpreter exited 0
local function probe_ok(res)
  return res ~= nil and res.code == 0
end

--- Synchronous probe, bounded by PROBE_TIMEOUT_MS. For explicit, user-requested
--- checks (`:checkhealth`) where blocking is acceptable; the backends' hot path
--- uses `python_module_cached()` / `probe_python_module()` instead.
---@param module string
---@return boolean
function M.has_python_module(module)
  local cache_key = "pymod:" .. module
  if _exe_cache[cache_key] ~= nil then return _exe_cache[cache_key] end
  if not M.python() then
    _exe_cache[cache_key] = false
    return false
  end
  local ok, res = pcall(function()
    return vim.system(probe_argv(module), { timeout = PROBE_TIMEOUT_MS }):wait()
  end)
  local result = ok and probe_ok(res)
  _exe_cache[cache_key] = result
  return result
end

--- What is already known about a module: true/false once probed, nil while
--- nothing has been probed yet. Never spawns anything.
---@param module string
---@return boolean|nil
function M.python_module_cached(module)
  return _exe_cache["pymod:" .. module]
end

--- Probe a module without blocking the editor. The result is cached (a timeout
--- or spawn failure counts as "absent"); concurrent calls for the same module
--- share one interpreter process. `on_done` runs on the main loop.
---@param module string
---@param on_done? fun(ok: boolean)
function M.probe_python_module(module, on_done)
  local cache_key = "pymod:" .. module
  local known = _exe_cache[cache_key]
  if known ~= nil then
    if on_done then on_done(known) end
    return
  end
  if not M.python() then
    _exe_cache[cache_key] = false
    if on_done then on_done(false) end
    return
  end
  if _probe_waiting[module] then
    if on_done then table.insert(_probe_waiting[module], on_done) end
    return
  end
  local waiting = {}
  if on_done then waiting[1] = on_done end
  _probe_waiting[module] = waiting
  local generation = _probe_generation

  local function finish(result)
    if generation ~= _probe_generation then return end
    _exe_cache[cache_key] = result
    _probe_waiting[module] = nil
    for _, cb in ipairs(waiting) do cb(result) end
  end

  local started = pcall(vim.system, probe_argv(module), { timeout = PROBE_TIMEOUT_MS }, function(res)
    vim.schedule(function()
      finish(probe_ok(res))
    end)
  end)
  if not started then finish(false) end
end

--- `available()` for a backend that needs a Python module: the cached answer, or
--- (while unknown) false plus a background probe, so the first resolution of the
--- fallback chain skips the backend instead of blocking on the interpreter start.
---@param module string
---@return boolean
function M.python_module_ready(module)
  if not M.python() then return false end
  local known = M.python_module_cached(module)
  if known == nil then
    M.probe_python_module(module)
    return false
  end
  return known
end

--- Name of the executable that opens a path/URL with the OS default handler.
--- Informational only — the `system` renderer dispatches through
--- lib.nvim.cross.open_default, not this string; :checkhealth uses it to show
--- what that dispatch resolves to. The names mirror open_default's own choices:
--- `explorer.exe` on native Windows (never a bare `start`, which is a cmd.exe
--- built-in, not a spawnable executable), `open` on macOS, xdg-open/wsl-open
--- elsewhere.
---@return string|nil
function M.open_cmd()
  local os = M.os()
  if os == "macos" then
    return "open"
  elseif os == "windows" then
    return "explorer.exe"
  else
    return M.first_available({ "xdg-open", "wsl-open" })
  end
end

--- Which terminal image tool to use for the page preview.
---
--- ueberzug/ueberzugpp is deliberately not a candidate: it is not a
--- "render into this pty" tool like the three below. It is a daemon that
--- draws a separate X11/Wayland child window over the terminal, positioned
--- by absolute cell coordinates and fed JSON over a FIFO — it cannot be
--- driven from a `:terminal` split at all, and the old `"ueberzug"` return
--- here was silently remapped to chafa anyway. In-Neovim overlay rendering
--- is `lib.nvim.image_preview`'s job (Kitty/OSC-1337 graphics protocols),
--- not this renderer's.
---@return "chafa"|"kitty"|"imgcat"|nil
function M.best_terminal_renderer()
  local term = vim.env.TERM or ""
  local term_prog = vim.env.TERM_PROGRAM or ""
  if term == "xterm-kitty" or term_prog == "kitty" then
    if M.has("kitten") or M.has("kitty") then return "kitty" end
  end
  if M.has("imgcat") then return "imgcat" end
  if M.has("chafa") then return "chafa" end
  return nil
end

function M.reset_cache()
  _exe_cache = {}
  _probe_generation = _probe_generation + 1
  _probe_waiting = {}
  _python_cache = nil
  _python_resolved = false
end

return M
