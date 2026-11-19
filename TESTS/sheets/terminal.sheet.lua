-- Feature sheet: `:PdfPort terminal <file> pages=1` rasterizes the page (pdftoppm of poppler, real) and shows
-- it through a terminal image tool in a split. chafa is a recording stand-in that prints a line instead of
-- an image. Once by hand: real chafa draws the page (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
return {
  id = "pdfport.terminal",
  feature = "pdfport.terminal",
  title = "pdfport: :PdfPort terminal pages=1 shows the rasterized page through chafa",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = 'vim.fn.executable("pdftoppm") == 1',
      reason = "pdftoppm (poppler) is not installed here",
    },
  },
  steps = {
    {
      lua = S
        .. [[.project() _G.sheet.setup() _G.sheet.stand_ins({ chafa = { stdout = "chafa drew the page" } })]],
      note = "a project with doc.pdf; chafa is a recording stand-in",
    },
    { keys = ":PdfPort terminal doc.pdf pages=1<CR>", note = "page 1 as a terminal image" },
    {
      wait = [[#_G.sheet.calls("chafa") == 1]],
      timeout = 10000,
      note = "chafa was started after the page was rasterized",
    },
    {
      -- joined: the Windows stand-in splits `--size=WxH` at the `=` (testing.nvim, a known limit)
      expect = [[table.concat(_G.sheet.calls("chafa")[1].argv, " "):find("^%-%-size[= ]%d+x%d+ .+%.png$") ~= nil]],
      note = "with a size from the editor and the PNG of the page",
    },
    {
      wait = [[_G.sheet.window_with("chafa drew the page", false) ~= nil]],
      timeout = 5000,
      note = "a terminal split shows what chafa printed",
    },
    {
      expect = [[vim.bo[vim.api.nvim_win_get_buf(_G.sheet.window_with("chafa drew the page", false))].buftype == "terminal"]],
      note = "it is a terminal buffer",
    },
  },
  judge = {},
  manual = { "with real chafa in a terminal: the page is drawn legibly in the split" },
}
