-- Feature sheet: with the cursor on a PDF name in the notes, a bare `:PdfPort` asks how to open it; the user
-- picks "Plain text (pdftotext)" and gets the text in a buffer. Without a selection UI plugin the choice is
-- Neovim's own vim.ui.select (an inputlist). pdftotext of poppler is real (n/a without it; CI installs it).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.open",
  feature = "pdfport.open",
  title = "pdfport: :PdfPort on a PDF name asks how to open it, plain text opens a buffer",
  engine = "rpc",
  sizes = { { rows = 30, cols = 100 } },
  prompts = "real",
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
    { keys = "/doc.pdf<CR>", note = "the cursor on the PDF name in the notes" },
    -- the inputlist holds every RPC call back until it is answered, so the answer is queued right behind
    { input = ":PdfPort<CR>", note = "ask pdfport to open the file under the cursor" },
    { input = "2<CR>", note = "the list of ways to open it: 2 is Plain text (pdftotext)" },
    {
      wait = [[_G.sheet.window_with("Beta page two", false) ~= nil]],
      timeout = 10000,
      note = "a window shows the text of the PDF",
    },
    {
      expect = [[vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(_G.sheet.window_with("Beta page two", false))):find("doc", 1, true) ~= nil]],
      note = "the buffer is named after the PDF",
    },
  },
  judge = { "the list names each way to open the PDF clearly" },
  manual = {},
}
