-- Hand probe as a sheet: the same with netrw (`:Lexplore`), which is part of Neovim and always there.
-- netrw counts as a sidebar for pdfport.
return {
  id = "pdfport.sidebar-netrw",
  title = "pdfport: the result opens in the editor window, not in a netrw sidebar",
  task = "pdfport.nvim/handprobe-sidebar-erkennung-mit-echten-file-trees",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = [[vim.fn.exists(":Lexplore") == 2]],
      reason = "netrw is not loaded in this editor (no :Lexplore)",
    },
  },
  steps = {
    {
      lua = [[local T = dofile(vim.fn.getcwd() .. "/TESTS/support/trees.lua")
      T.project()
      vim.cmd("Lexplore " .. vim.fn.fnameescape(_G.sheet_root))]],
      note = "a project with a.txt in the editor window, netrw opened on the left",
    },
    {
      wait = [[vim.bo.filetype == "netrw"]],
      timeout = 5000,
      note = "the focus is in the netrw window",
    },
    {
      expect = [[require("lib.nvim.explorer").current(0) == "netrw"]],
      note = "lib.nvim.explorer knows the focused buffer as netrw",
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
      expect = [[vim.bo[vim.api.nvim_win_get_buf(_G.tree_win)].filetype == "netrw"]],
      note = "the sidebar still shows netrw, not the result",
    },
  },
  judge = {},
  manual = {},
}
