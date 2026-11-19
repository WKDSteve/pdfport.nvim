-- Feature sheet: `:PdfPort text <file>` extracts a PDF into a buffer beside the notes that name it, through
-- the first available backend (pdftotext of poppler, real). Without poppler on the machine the sheet is a
-- reported n/a; the CI legs install it.
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.text",
  feature = "pdfport.text",
  title = "pdfport: :PdfPort text shows the text of every page in a buffer",
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
    { keys = ":PdfPort text doc.pdf<CR>", note = "extract the PDF named in the notes" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil]],
      timeout = 10000,
      note = "a window shows the extracted text",
    },
    {
      expect = [[_G.sheet.window_with("Alpha page one", false) == _G.sheet.window_with("Beta page two", false)]],
      note = "both pages are in it, in one buffer",
    },
    {
      expect = [[#vim.api.nvim_tabpage_list_wins(0) == 2 and vim.api.nvim_win_get_buf(_G.editor_win) ~= vim.api.nvim_win_get_buf(_G.sheet.window_with("Beta page two", false))]],
      note = "the notes stay open beside it",
    },
  },
  judge = { "the text reads like the PDF: one line per page, the layout kept" },
  manual = {},
}
