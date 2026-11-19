-- Feature sheet: a user who picks a Python backend (pdfplumber, docling) or marker as `default_backend` gets
-- the PDF through it. The first `:PdfPort backends` asks Python in the background whether the modules import;
-- then `:PdfPort text` runs the backend's script through Python, or `marker_single`. python3 and marker_single
-- are recording stand-ins that print the text (no model, no conversion in a sheet); on Windows libuv cannot
-- start a `.cmd` stand-in, there each start is made and pdfport reports it failed. Once by hand: the real
-- backends on a table-heavy PDF (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
local function setup(backend)
  return ('_G.sheet.setup({ default_backend = "%s", extract_opts = { cache = false } })'):format(
    backend
  )
end
return {
  id = "pdfport.python-backends",
  feature = "pdfport.text",
  title = "pdfport: pdfplumber, docling and marker extract when they are the configured backend",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  steps = {
    {
      lua = S .. [[.project()
      _G.sheet.stand_ins({ python3 = { stdout = "Text through Python" }, marker_single = {} })
      ]] .. setup("pdfplumber"),
      note = "a project with doc.pdf; python3 and marker_single are stand-ins, pdfplumber the backend",
    },
    { keys = ":PdfPort backends<CR>", note = "the list of backends" },
    {
      wait = [[_G.sheet.window_with("pdfplumber", true) ~= nil
        and require("pdfport.platform").python_module_cached("pdfplumber") ~= nil
        and require("pdfport.platform").python_module_cached("docling") ~= nil]],
      timeout = 5000,
      note = "it is shown, and Python was asked in the background about pdfplumber and docling",
    },
    { keys = ":PdfPort backends<CR>", note = "the list again" },
    {
      wait = [[_G.sheet.text(vim.api.nvim_win_get_buf(_G.sheet.window_with("pdfplumber", true))):find("pdfplumber%s+available") ~= nil]],
      timeout = 5000,
      note = "now pdfplumber is listed as available",
    },
    { keys = "q", note = "close the list" },
    {
      keys = ":PdfPort text doc.pdf<CR>",
      ignore_errmsg = true,
      note = "extract through pdfplumber",
    },
    {
      wait = [[_G.sheet.asked("python3", 1, "%.py$")]],
      timeout = 5000,
      note = "pdfplumber's script ran in Python",
    },
    {
      wait = [[not _G.sheet.uv_reaches_stand_ins() or _G.sheet.window_with("Text through Python", false) ~= nil]],
      timeout = 5000,
      note = "its text is shown",
    },
    { lua = setup("docling"), note = "the user switches to docling" },
    { keys = ":PdfPort text doc.pdf<CR>", ignore_errmsg = true, note = "extract through docling" },
    {
      wait = [[_G.sheet.asked("python3", 2, "%.py$")]],
      timeout = 5000,
      note = "docling's script ran in Python",
    },
    { lua = setup("marker"), note = "the user switches to marker" },
    { keys = ":PdfPort text doc.pdf<CR>", ignore_errmsg = true, note = "extract through marker" },
    {
      wait = [[_G.sheet.asked("marker_single")]],
      timeout = 5000,
      note = "marker_single was started",
    },
    {
      expect = [[not _G.sheet.uv_reaches_stand_ins()
        or (_G.sheet.calls("marker_single")[1].argv[1]:find("doc.pdf$") ~= nil
          and table.concat(_G.sheet.calls("marker_single")[1].argv, " "):find("--output_format markdown", 1, true) ~= nil)]],
      note = "with the PDF and Markdown as the output format",
    },
  },
  judge = {},
  manual = {
    "with pdfplumber, docling and marker installed: each gives a readable text of a PDF with a table",
  },
}
