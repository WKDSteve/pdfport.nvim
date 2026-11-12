-- Hand probe as a sheet: oil is an explorer for lib.nvim but NOT a sidebar for pdfport: with the focus in
-- an oil window (a split of its own) the result stays in that window, the editor window is untouched.
-- Without oil.nvim on the machine the sheet is a reported n/a.
local T = 'dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")'
return {
  id = "pdfport.sidebar-oil",
  feature = "pdfport.file-trees",
  title = "pdfport: an oil window is not a sidebar, the result stays in it",
  task = "pdfport.nvim/handprobe-sidebar-erkennung-mit-echten-file-trees",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    { lua = T .. '.have({ "oil.nvim" })', reason = "oil.nvim is not installed here" },
  },
  steps = {
    {
      lua = [[local T = dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")
      T.use({ "nvim-web-devicons", "oil.nvim" })
      T.project()
      require("oil").setup({})
      vim.cmd("vsplit")
      _G.oil_win = vim.api.nvim_get_current_win()
      require("oil").open(_G.sheet_root)]],
      note = "a project with a.txt in one window, an oil window beside it with the focus",
    },
    {
      wait = [[vim.bo.filetype == "oil"]],
      timeout = 5000,
      note = "the focus is in the oil window",
    },
    {
      expect = [[require("lib.nvim.explorer").current(0) == "oil"]],
      note = "lib.nvim.explorer knows the focused buffer as oil",
    },
    {
      lua = [[_G.trees.render()]],
      note = "pdfport renders a result while the oil window has the focus",
    },
    {
      expect = [[vim.api.nvim_get_current_win() == _G.oil_win]],
      note = "the focus stayed in the oil window",
    },
    {
      expect = [[_G.trees.on_result()]],
      note = "the oil window shows the pdfport result",
    },
    {
      expect = [[vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(_G.editor_win)):find("a.txt", 1, true) ~= nil]],
      note = "the other window still shows a.txt",
    },
  },
  judge = {},
  manual = {},
}
