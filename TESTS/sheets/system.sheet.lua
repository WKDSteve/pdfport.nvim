-- Feature sheet: `:PdfPort system <file>` hands the original PDF to the system application. The opener is a
-- recording stand-in, never a real window: lib.nvim's platform switch is turned to the Linux branch on every
-- system (its `explorer.exe`/`open` cannot be caught by a `.cmd` stand-in on Windows), so `xdg-open` is the
-- program asked. Once by hand: the real opener of each system shows the PDF (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.system",
  feature = "pdfport.system",
  title = "pdfport: :PdfPort system hands the PDF to the system opener",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  steps = {
    {
      lua = S .. [[.project() _G.sheet.setup() _G.sheet.stand_ins({ ["xdg-open"] = {} })
      for _, name in ipairs({ "is_windows", "is_wsl", "is_macos" }) do
        package.loaded["lib.nvim.cross.platform." .. name] = function() return false end
      end]],
      note = "a project with doc.pdf; xdg-open is a recording stand-in, the platform switch says Linux",
    },
    { keys = ":PdfPort system doc.pdf<CR>", note = "open the PDF with the system application" },
    {
      wait = [[#_G.sheet.calls("xdg-open") == 1]],
      timeout = 5000,
      note = "the opener was asked once",
    },
    {
      expect = [[_G.sheet.calls("xdg-open")[1].argv[1]:gsub("\\", "/"):find("/doc.pdf$") ~= nil]],
      note = "with the PDF's absolute path",
    },
    {
      expect = [[#vim.api.nvim_tabpage_list_wins(0) == 1 and not _G.sheet.noted("could not")]],
      note = "the editor stays as it was, no error",
    },
  },
  judge = {},
  manual = {
    "on Windows, macOS and Linux each: :PdfPort system on a PDF opens it in the default PDF viewer",
  },
}
