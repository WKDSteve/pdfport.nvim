-- Hand probe as a sheet: pdfport opens its result in the editor window when the focus is in a real
-- neo-tree sidebar (task pdfport.nvim/handprobe-sidebar-erkennung-mit-echten-file-trees). The plugin is
-- looked up on the machine (TESTS/support/trees.lua); without it the sheet is a reported n/a.
local T = 'dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")'
return {
  id = "pdfport.sidebar-neo-tree",
  title = "pdfport: the result opens in the editor window, not in a neo-tree sidebar",
  task = "pdfport.nvim/handprobe-sidebar-erkennung-mit-echten-file-trees",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = T .. '.have({ "neo-tree.nvim", "nui.nvim", "plenary.nvim" })',
      reason = "neo-tree.nvim (with nui.nvim and plenary.nvim) is not installed here",
    },
  },
  steps = {
    {
      lua = [[local T = dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")
      T.use({ "nui.nvim", "plenary.nvim", "nvim-web-devicons", "neo-tree.nvim" })
      T.project()
      require("neo-tree").setup({ filesystem = { hijack_netrw_behavior = "disabled" }, enable_git_status = false })
      require("neo-tree.command").execute({ action = "focus", source = "filesystem", position = "left", dir = _G.sheet_root })]],
      note = "a project with a.txt in the editor window, neo-tree open and focused on the left",
    },
    {
      wait = [[vim.bo.filetype == "neo-tree"]],
      timeout = 5000,
      note = "the focus is in the neo-tree window",
    },
    {
      expect = [[require("lib.nvim.explorer").current(0) == "neo-tree"]],
      note = "lib.nvim.explorer knows the focused buffer as neo-tree",
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
      expect = [[vim.bo[vim.api.nvim_win_get_buf(_G.tree_win)].filetype == "neo-tree"]],
      note = "the sidebar still shows neo-tree, not the result",
    },
  },
  judge = {},
  manual = {},
}
