-- Feature sheet: the first `:PdfPort text` of a session asks Python whether pdfplumber/docling import only
-- when the fallback chain can reach them. With pdftotext (real poppler) first and available, no Python
-- starts at all: `import docling` alone loads its ML dependencies. python3 is a stand-in that would say
-- "not installed"; the check reads pdfport's own module cache, which any probe fills (on Windows too, where
-- the start of the stand-in may fail: that also counts as answered). The reached case is
-- python-probe-reached.sheet.lua.
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.python-probe",
  feature = "pdfport.text",
  title = "pdfport: with pdftotext available the first extraction starts no Python",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = 'vim.fn.executable("pdftotext") == 1',
      reason = "pdftotext (poppler) is not installed here",
    },
  },
  steps = {
    {
      lua = S .. [[.project()
      _G.sheet.stand_ins({ python3 = { exit_code = 1 } })
      _G.sheet.setup()]],
      note = "a project with doc.pdf, pdfport set up with the default chain (pdftotext first)",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "extract the PDF" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil]],
      timeout = 10000,
      note = "pdftotext's text is shown",
    },
    { lua = "vim.wait(1000)", note = "time for a background probe to start and answer" },
    {
      expect = [[require("pdfport.platform").python_module_cached("pdfplumber") == nil
        and require("pdfport.platform").python_module_cached("docling") == nil
        and #_G.sheet.calls("python3") == 0]],
      note = "Python was never asked about pdfplumber or docling",
    },
  },
  judge = {},
  manual = {},
}
