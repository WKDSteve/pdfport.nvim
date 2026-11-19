-- Feature sheet: an extraction is cached across restarts. The user opens a PDF, quits, starts the editor
-- again and opens the same PDF: the text is there at once, from the cache (the `debug` trace says so), and
-- pdftotext does not run again. pdftotext of poppler is real (n/a without it; the CI legs install it).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
local PROJECT = 'vim.fn.stdpath("data") .. "/project"'
return {
  id = "pdfport.cache",
  feature = "pdfport.cache",
  title = "pdfport: the same PDF after a restart comes from the cache",
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
      lua = S .. ".project(" .. PROJECT .. ") _G.sheet.setup({ debug = true })",
      note = "a project with notes.md and a two-page doc.pdf, pdfport with its debug trace",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "the first extraction" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil and _G.sheet.noted("cache miss")]],
      timeout = 10000,
      note = "the text is shown, extracted by pdftotext (cache miss)",
    },
    { restart = true, note = "quit and start the editor again" },
    {
      lua = S .. ".project(" .. PROJECT .. ") _G.sheet.setup({ debug = true })",
      note = "the same project and config",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "the same PDF again" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil]],
      timeout = 10000,
      note = "the text is shown",
    },
    {
      expect = [[_G.sheet.noted("cache hit") and not _G.sheet.noted("cache miss")]],
      note = "it came from the cache: no second extraction",
    },
  },
  judge = {},
  manual = {},
}
