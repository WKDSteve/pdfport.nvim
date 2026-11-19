-- Feature sheet: `:PdfPort float <file> pages=2` shows only the asked page of a PDF in a centered float over
-- the notes; `q` closes it. pdftotext of poppler runs for real (n/a without it; the CI legs install it).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.float",
  feature = "pdfport.float",
  title = "pdfport: :PdfPort float pages=2 shows that page in a float",
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
      lua = S .. ".project() _G.sheet.setup()",
      note = "a project with notes.md and a two-page doc.pdf, pdfport set up as a user does",
    },
    { keys = ":PdfPort float doc.pdf pages=2<CR>", note = "page 2 of the PDF in a float" },
    {
      wait = [[_G.sheet.window_with("Beta page two", true) ~= nil]],
      timeout = 10000,
      note = "a float shows page 2",
    },
    {
      expect = [[_G.sheet.window_with("Alpha page one") == nil]],
      note = "page 1 is not in it",
    },
    {
      expect = [[vim.api.nvim_get_current_win() == _G.sheet.window_with("Beta page two", true)]],
      note = "the float has the focus",
    },
    { keys = "q", note = "close it" },
    {
      wait = [[_G.sheet.window_with("Beta page two") == nil and vim.api.nvim_get_current_win() == _G.editor_win]],
      note = "the float is gone, the notes have the focus again",
    },
  },
  judge = { "the float sits in the middle and is large enough for the page" },
  manual = {},
}
