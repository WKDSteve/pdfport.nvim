-- Feature sheet: in netrw (part of Neovim) the user selects the lines of two PDFs and presses <leader>pb:
-- both open as text, each in a split, and pdfport says how many it opened. pdftotext of poppler is real
-- (n/a without it; the CI legs install it).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.batch-open",
  feature = "pdfport.batch-open",
  title = "pdfport: <leader>pb on two PDFs selected in netrw opens both",
  engine = "rpc",
  sizes = { { rows = 30, cols = 140 } },
  requires = {
    {
      lua = 'vim.fn.executable("pdftotext") == 1',
      reason = "pdftotext (poppler) is not installed here",
    },
    {
      lua = [[vim.fn.exists(":Explore") == 2]],
      reason = "netrw is not loaded in this editor (no :Explore)",
    },
  },
  steps = {
    {
      lua = S .. [[.project()
      _G.sheet.write_pdf("more.pdf", { "Gamma page three" })
      vim.g.mapleader = " "
      _G.sheet.setup()
      require("pdfport").netrw().setup()]],
      note = "a project with doc.pdf, more.pdf and notes.md; pdfport's netrw keys are on, <Space> is the leader",
    },
    -- netrw itself leaves `E31: No such mapping` in v:errmsg (a `silent!` unmap of its own), with or without pdfport
    { keys = ":Explore<CR>", ignore_errmsg = true, note = "netrw on the project" },
    { wait = [[vim.bo.filetype == "netrw"]], timeout = 5000, note = "netrw lists the files" },
    { keys = "/^doc\\.pdf<CR>", note = "the cursor on doc.pdf" },
    { keys = "Vj", note = "select doc.pdf and more.pdf" },
    { keys = " pb", note = "<leader>pb: open the selected PDFs" },
    {
      wait = [[_G.sheet.noted("opened 2 PDF(s)")]],
      timeout = 10000,
      note = "pdfport says it opened both",
    },
    {
      expect = [[_G.sheet.window_with("Beta page two", false) ~= nil and _G.sheet.window_with("Gamma page three", false) ~= nil]],
      note = "both texts are shown, each in a window of its own",
    },
  },
  judge = {},
  manual = {},
}
