-- Feature sheet: a user with Tesseract as the backend (a scanned PDF) runs `:PdfPort text`: pdfport rasterizes
-- page 1 (pdftoppm of poppler, real), hands the PNG to tesseract (a recording stand-in that prints the words)
-- and, since no page was asked for, says that only page 1 of 2 was read (pdfinfo of poppler, real).
-- On Windows libuv cannot start the `.cmd` stand-in: there the start is made and pdfport reports it failed.
-- Once by hand: real Tesseract reads a scanned page (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.ocr",
  feature = "pdfport.ocr",
  title = "pdfport: with the tesseract backend :PdfPort text reads page 1 through OCR",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = 'vim.fn.executable("pdftoppm") == 1 and vim.fn.executable("pdfinfo") == 1',
      reason = "pdftoppm and pdfinfo (poppler) are not installed here",
    },
  },
  steps = {
    {
      lua = S .. [[.project()
      _G.sheet.stand_ins({ tesseract = { stdout = "Scanned words of the page" } })
      _G.sheet.setup({ default_backend = "tesseract", extract_opts = { cache = false } })]],
      note = "a project with doc.pdf; tesseract (a recording stand-in) is the configured backend",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "extract the PDF" },
    {
      wait = [[_G.sheet.asked("tesseract")]],
      timeout = 10000,
      note = "tesseract was started on the rasterized page",
    },
    {
      wait = [[not _G.sheet.uv_reaches_stand_ins()
        or (_G.sheet.window_with("Scanned words of the page", false) ~= nil and _G.sheet.noted("only page 1 of 2"))]],
      timeout = 10000,
      note = "the OCR text is shown, with the notice that only page 1 of 2 was read",
    },
    {
      expect = [[not _G.sheet.uv_reaches_stand_ins()
        or (_G.sheet.calls("tesseract")[1].argv[1]:find("%.png$") ~= nil and _G.sheet.calls("tesseract")[1].argv[2] == "stdout")]],
      note = "tesseract got the PNG of the page and wrote to stdout",
    },
  },
  judge = {},
  manual = { "with real Tesseract: a scanned PDF (no text layer) comes out as readable text" },
}
