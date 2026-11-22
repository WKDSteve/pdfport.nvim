-- Feature sheet: when the fallback chain reaches a Python backend before an available one, the first
-- `:PdfPort text` asks Python about it in the background -- and only about it. The chain is
-- marker (no marker_single here), pdfplumber, pdftotext (real poppler): pdfplumber is probed, the text
-- comes from pdftotext, docling (behind pdftotext) is never asked. python3 is a stand-in that says "not
-- installed"; on Windows its start may fail, which pdfport also records as "not installed".
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.python-probe-reached",
  feature = "pdfport.text",
  title = "pdfport: a Python backend the chain reaches is probed in the background, the rest is not",
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
      _G.sheet.setup({ fallback_chain = { "marker", "pdfplumber", "pdftotext" } })]],
      note = "a project with doc.pdf; the chain puts pdfplumber before pdftotext, marker is missing",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "extract the PDF" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil]],
      timeout = 10000,
      note = "pdftotext's text is shown (pdfplumber is not known yet, so it is skipped)",
    },
    {
      wait = [[require("pdfport.platform").python_module_cached("pdfplumber") == false]],
      timeout = 5000,
      note = "Python was asked about pdfplumber and answered: not installed",
    },
    {
      expect = [[require("pdfport.platform").python_module_cached("docling") == nil]],
      note = "docling, behind the available pdftotext, was never asked",
    },
  },
  judge = {},
  manual = {},
}
