-- Feature sheet: `:PdfPort create <file>` makes a PDF from an image, Markdown, HTML and an office document,
-- each through the first producer of its kind (img2pdf, pandoc with an engine, weasyprint, soffice); with a
-- chain of the user's own (`create_chain`) the image goes to ImageMagick and the HTML to a Chromium browser.
-- Every converter is a recording stand-in (no conversion in a sheet); on Windows libuv cannot start a `.cmd`
-- stand-in, there each start is made and pdfport reports it failed. Once by hand: the real converters (manual).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
local SOURCES = [[
vim.fn.writefile({ "fake image bytes" }, "picture.png")
vim.fn.writefile({ "<html><body><p>Hello</p></body></html>" }, "page.html")
vim.fn.writefile({ "fake office bytes" }, "letter.docx")]]
local STAND_INS = [[_G.sheet.stand_ins({
  img2pdf = {}, magick = {}, pandoc = {}, tectonic = {}, weasyprint = {}, chrome = {}, soffice = {},
})]]
return {
  id = "pdfport.create",
  feature = "pdfport.create",
  title = "pdfport: :PdfPort create hands each kind of file to its producer",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  steps = {
    {
      lua = S .. ".project()" .. SOURCES .. "\n" .. STAND_INS .. "\n_G.sheet.setup()",
      note = "a project with notes.md, picture.png, page.html and letter.docx; the converters are stand-ins",
    },
    {
      keys = ":PdfPort create picture.png<CR>",
      ignore_errmsg = true,
      note = "a PDF from the image",
    },
    { wait = [[_G.sheet.asked("img2pdf")]], timeout = 5000, note = "img2pdf was started" },
    {
      keys = ":PdfPort create notes.md<CR>",
      ignore_errmsg = true,
      note = "a PDF from the Markdown notes",
    },
    { wait = [[_G.sheet.asked("pandoc")]], timeout = 5000, note = "pandoc was started" },
    {
      expect = [[not _G.sheet.uv_reaches_stand_ins()
        or table.concat(_G.sheet.calls("pandoc")[1].argv, " "):find("tectonic", 1, true) ~= nil]],
      note = "with the PDF engine it found (tectonic)",
    },
    {
      keys = ":PdfPort create page.html<CR>",
      ignore_errmsg = true,
      note = "a PDF from the HTML page",
    },
    { wait = [[_G.sheet.asked("weasyprint")]], timeout = 5000, note = "weasyprint was started" },
    {
      keys = ":PdfPort create letter.docx<CR>",
      ignore_errmsg = true,
      note = "a PDF from the Word document",
    },
    { wait = [[_G.sheet.asked("soffice")]], timeout = 5000, note = "soffice was started" },
    {
      lua = [[_G.sheet.setup({ create_chain = { image = { "magick" }, html = { "chromium" } } })]],
      note = "the user's own chain: images through ImageMagick, HTML through a Chromium browser",
    },
    { keys = ":PdfPort create picture.png<CR>", ignore_errmsg = true, note = "the image again" },
    { wait = [[_G.sheet.asked("magick")]], timeout = 5000, note = "magick was started" },
    { keys = ":PdfPort create page.html<CR>", ignore_errmsg = true, note = "the HTML page again" },
    { wait = [[_G.sheet.asked("chrome")]], timeout = 5000, note = "the browser was started" },
    {
      expect = [[not _G.sheet.uv_reaches_stand_ins()
        or table.concat(_G.sheet.calls("chrome")[1].argv, " "):find("--headless", 1, true) ~= nil]],
      note = "headless, printing to PDF",
    },
    {
      expect = [[#vim.api.nvim_tabpage_list_wins(0) == 1]],
      note = "the editor layout is untouched: the result is a notification",
    },
  },
  judge = {},
  manual = {
    "with img2pdf, pandoc + an engine, weasyprint, soffice, magick and Chrome installed: each :PdfPort create writes a PDF that opens",
  },
}
