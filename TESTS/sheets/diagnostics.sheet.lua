-- Feature sheet: `:PdfPort health` and `:PdfPort backends` say what this machine has. The checkhealth page asks
-- Python whether pdfplumber and docling import and asks a local ollama daemon for its models (curl); the
-- backends list names every backend with its availability. python3, ollama and curl are recording stand-ins
-- (the daemon answers with no models), so the page is the same on every machine.
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.diagnostics",
  feature = "pdfport.diagnostics",
  title = "pdfport: :PdfPort health and :PdfPort backends report the tools of this machine",
  engine = "rpc",
  sizes = { { rows = 30, cols = 110 } },
  steps = {
    {
      lua = S
        .. [[.project()
      _G.sheet.stand_ins({ python3 = {}, ollama = {}, curl = { stdout = '{"models":[]}\n200' } })
      _G.sheet.setup()]],
      note = "a project; python3 (every module imports), ollama and curl are stand-ins",
    },
    -- checkhealth computes before it returns: queued, then waited for
    { input = ":PdfPort health<CR>", note = "the health page of pdfport" },
    {
      wait = [[vim.bo.filetype == "checkhealth" and _G.sheet.text(0):find("pdfport", 1, true) ~= nil
        and _G.sheet.text(0):find("ollama", 1, true) ~= nil]],
      timeout = 30000,
      note = "the checkhealth page shows pdfport's report",
    },
    {
      expect = [[#vim.tbl_filter(function(c) return c.argv[1] == "-c" end, _G.sheet.calls("python3")) >= 2]],
      note = "Python was asked for the modules (pdfplumber, docling)",
    },
    {
      -- on Windows the `.cmd` stand-in stops recording at the argument with a line break (`\n%{http_code}`)
      expect = [[#_G.sheet.calls("curl") == 1 and (vim.fn.has("win32") == 1
        or table.concat(_G.sheet.calls("curl")[1].argv, " "):find("localhost:11434/api/tags", 1, true) ~= nil)]],
      note = "the ollama daemon was asked for its models",
    },
    { keys = ":tabclose<CR>", note = "close the health page" },
    { keys = ":PdfPort backends<CR>", note = "the list of backends" },
    {
      wait = [[_G.sheet.window_with("pdftotext", true) ~= nil]],
      timeout = 5000,
      note = "a float lists the backends",
    },
    {
      expect = [[_G.sheet.text(vim.api.nvim_win_get_buf(_G.sheet.window_with("pdftotext", true))):find("pdftotext%s+available") ~= nil
        or vim.fn.executable("pdftotext") == 0]],
      note = "pdftotext is listed as available where poppler is installed",
    },
  },
  judge = { "the health page says in one line per tool what is there and what it enables" },
  manual = {},
}
