-- TESTS/setup_no_process_spec.lua -- loading and setting up start no process (SEC-22); the Python-module
-- probe is warmed on the first open/extract instead, once.

return function(H)
  local platform = require("pdfport.platform")
  local probed = {}
  local real_probe, real_python = platform.probe_python_module, platform.python
  platform.python = function()
    return "python3"
  end
  platform.probe_python_module = function(module)
    probed[#probed + 1] = module
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

  local ok, err = pcall(function()
    local pdfport = require("pdfport")
    pdfport.setup({ deps_popup = false })
    vim.wait(100)
    H.eq(#probed, 0, "setup() probes no Python module")

    pdfport.extract({ path = "a.pdf", __callback = function() end })
    vim.wait(2000, function()
      return #probed == 2
    end, 10)
    H.eq(#probed, 2, "the first extract warms both probes")
    H.eq(dispatched, 1, "and still dispatches")

    pdfport.open({ path = "b.pdf" })
    vim.wait(100)
    H.eq(#probed, 2, "later calls do not probe again")
    H.eq(dispatched, 2, "but still dispatch")
  end)

  platform.probe_python_module, platform.python = real_probe, real_python
  package.loaded["pdfport.core.dispatcher"] = real_dispatcher
  if not ok then error(err, 0) end
end
