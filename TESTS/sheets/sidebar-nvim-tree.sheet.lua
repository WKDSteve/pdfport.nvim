-- Hand probe as a sheet: the same with a real nvim-tree sidebar. nvim-tree is not installed on every
-- machine; then the sheet is a reported n/a, never a green run.
local T = 'dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")'
return {
  id = "pdfport.sidebar-nvim-tree",
  title = "pdfport: the result opens in the editor window, not in an nvim-tree sidebar",
  task = "pdfport.nvim/handprobe-sidebar-erkennung-mit-echten-file-trees",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    { lua = T .. '.have({ "nvim-tree.lua" })', reason = "nvim-tree.lua is not installed here" },
  },
  steps = {
    {
      lua = [[local T = dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")
      T.use({ "nvim-web-devicons", "nvim-tree.lua" })
      T.project()
      vim.g.loaded_netrw, vim.g.loaded_netrwPlugin = 1, 1
      require("nvim-tree").setup({})
      require("nvim-tree.api").tree.open({ path = _G.sheet_root, focus = true })]],
      note = "a project with a.txt in the editor window, nvim-tree open and focused",
    },
    {
      wait = [[vim.bo.filetype == "NvimTree"]],
      timeout = 5000,
      note = "the focus is in the nvim-tree window",
    },
    {
      expect = [[require("lib.nvim.explorer").current(0) == "nvim-tree"]],
      note = "lib.nvim.explorer knows the focused buffer as nvim-tree",
    },
    {
      lua = [[_G.tree_win = vim.api.nvim_get_current_win()
      _G.trees.render()]],
      note = "pdfport renders a result while the sidebar has the focus",
    },
    {
      expect = [[vim.api.nvim_get_current_win() == _G.editor_win]],
      note = "the focus moved to the editor window",
    },
    {
      expect = [[_G.trees.on_result()]],
      note = "the editor window shows the pdfport result",
    },
    {
      expect = [[vim.bo[vim.api.nvim_win_get_buf(_G.tree_win)].filetype == "NvimTree"]],
      note = "the sidebar still shows nvim-tree, not the result",
    },
  },
  judge = {},
  manual = {},
}
