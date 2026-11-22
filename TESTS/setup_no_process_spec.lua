-- TESTS/setup_no_process_spec.lua -- loading and setting up start no process (SEC-22); the Python-module
-- probe is warmed on the first open/extract instead, once, and only for the Python backends the chain of
-- that request can reach (pdftotext first and available: no interpreter at all).

return function(H)
  local platform = require("pdfport.platform")
  local probed = {}
  local present = {}
  local real_probe, real_python, real_has =
    platform.probe_python_module, platform.python, platform.has
  platform.python = function()
    return "python3"
  end
  -- Records the probe and leaves the module unknown, as a probe still running would.
  platform.probe_python_module = function(module)
    probed[#probed + 1] = module
  end
  platform.has = function(exe)
    return present[exe] == true
  end

  local dispatched = 0
  local real_dispatcher = package.loaded["pdfport.core.dispatcher"]
  package.loaded["pdfport.core.dispatcher"] = {
    _set_config = function() end,
    open = function()
      dispatched = dispatched + 1
    end,
    dispatch = function()
      dispatched = dispatched + 1
    end,
  }

  -- A fresh session: pdfport reloaded (its once-per-session flag reset), set up with `cfg`, and the
  -- executables in `exes` on the PATH.
  local function session(cfg, exes)
    package.loaded["pdfport"] = nil
    probed, dispatched, present = {}, 0, {}
    for _, e in ipairs(exes) do
      present[e] = true
    end
    local pdfport = require("pdfport")
    pdfport.setup(vim.tbl_extend("force", { deps_popup = false }, cfg or {}))
    return pdfport
  end

  local function settle(n)
    vim.wait(2000, function()
      return #probed >= n
    end, 10)
    vim.wait(100)
  end

  local function extract(pdfport, backend_id)
    pdfport.extract({ path = "a.pdf", backend_id = backend_id, __callback = function() end })
  end

  local ok, err = pcall(function()
    -- pdftotext available: the chain ends there, no Python backend is reachable.
    local pdfport = session(nil, { "pdftotext" })
    vim.wait(100)
    H.eq(#probed, 0, "setup() probes no Python module")
    extract(pdfport)
    settle(1)
    H.eq(
      table.concat(probed, ","),
      "",
      "with pdftotext available the first extract starts no Python"
    )
    H.eq(dispatched, 1, "and still dispatches")

    -- Nothing before them is available: both Python backends are reachable and are probed.
    pdfport = session(nil, {})
    extract(pdfport)
    settle(2)
    H.eq(
      table.concat(probed, ","),
      "pdfplumber,docling",
      "without pdftotext the first extract warms both"
    )
    pdfport.open({ path = "b.pdf" })
    vim.wait(100)
    H.eq(#probed, 2, "later calls do not probe again")
    H.eq(dispatched, 2, "but still dispatch")

    -- Only what lies before the first available backend: marker missing, pdfplumber reached, then pdftotext.
    pdfport = session({ fallback_chain = { "marker", "pdfplumber", "pdftotext" } }, { "pdftotext" })
    extract(pdfport)
    settle(1)
    H.eq(
      table.concat(probed, ","),
      "pdfplumber",
      "only the Python backend the chain reaches is probed"
    )

    -- A request for a Python backend probes it even with pdftotext there.
    pdfport = session(nil, { "pdftotext" })
    extract(pdfport, "docling")
    settle(1)
    H.eq(table.concat(probed, ","), "docling", "a requested Python backend is probed")

    -- `default_backend` set to a Python backend: probed first.
    pdfport = session({ default_backend = "pdfplumber" }, { "pdftotext" })
    pdfport.open({ path = "c.pdf" })
    settle(1)
    H.eq(table.concat(probed, ","), "pdfplumber", "a Python default_backend is probed")
  end)

  platform.probe_python_module, platform.python, platform.has = real_probe, real_python, real_has
  package.loaded["pdfport.core.dispatcher"] = real_dispatcher
  if not ok then error(err, 0) end
end
