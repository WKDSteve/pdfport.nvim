-- Feature sheet: `:PdfPort merge <out.pdf> <a.pdf> <b.pdf>` joins PDFs through qpdf; with a chain of the user's
-- own (`create_chain.pdf`) through pdftk, then Ghostscript. The three are recording stand-ins (no conversion
-- in a sheet); on Windows libuv cannot start a `.cmd` stand-in, there each start is made and pdfport reports
-- it failed. Once by hand: a real merge (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.merge",
  feature = "pdfport.merge",
  title = "pdfport: :PdfPort merge joins PDFs through qpdf, pdftk or Ghostscript",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  steps = {
    {
      lua = S .. [[.project()
      _G.sheet.write_pdf("more.pdf", { "Gamma page three" })
      _G.sheet.stand_ins({ qpdf = {}, pdftk = {}, gs = {} })
      _G.sheet.setup()]],
      note = "a project with doc.pdf and more.pdf; qpdf, pdftk and gs are stand-ins",
    },
    {
      keys = ":PdfPort merge all.pdf doc.pdf more.pdf<CR>",
      ignore_errmsg = true,
      note = "join the two PDFs",
    },
    { wait = [[_G.sheet.asked("qpdf")]], timeout = 5000, note = "qpdf was started" },
    {
      expect = [[not _G.sheet.uv_reaches_stand_ins()
        or table.concat(_G.sheet.calls("qpdf")[1].argv, " "):find("doc.pdf.*more.pdf") ~= nil]],
      note = "with both inputs in order",
    },
    {
      lua = [[_G.sheet.setup({ create_chain = { pdf = { "pdftk" } } })]],
      note = "the user prefers pdftk",
    },
    {
      keys = ":PdfPort merge all2.pdf doc.pdf more.pdf<CR>",
      ignore_errmsg = true,
      note = "join them again",
    },
    { wait = [[_G.sheet.asked("pdftk")]], timeout = 5000, note = "pdftk was started" },
    {
      lua = [[_G.sheet.setup({ create_chain = { pdf = { "ghostscript" } } })]],
      note = "the user prefers Ghostscript",
    },
    {
      keys = ":PdfPort merge all3.pdf doc.pdf more.pdf<CR>",
      ignore_errmsg = true,
      note = "join them again",
    },
    { wait = [[_G.sheet.asked("gs")]], timeout = 5000, note = "Ghostscript (gs) was started" },
  },
  judge = {},
  manual = { "with qpdf installed: :PdfPort merge writes one PDF with the pages of both, in order" },
}
