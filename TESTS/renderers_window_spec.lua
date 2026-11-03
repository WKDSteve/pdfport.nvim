-- TESTS/renderers_window_spec.lua — pdfport.renderers._window, the open / restore_focus / close
-- helpers the buffer and terminal renderers share. Real windows; every window a case opens is
-- closed again and the starting layout is restored.

return function(H)
  local window = require("pdfport.renderers._window")
  local api = vim.api

  local start_win = api.nvim_get_current_win()
  local start_tab = api.nvim_get_current_tabpage()
  local made_bufs = {}
  local function scratch()
    local b = api.nvim_create_buf(false, true)
    made_bufs[#made_bufs + 1] = b
    return b
  end

  -- split / vsplit / new add a window and make it current; the buffer is shown in it
  for _, layout in ipairs({ "split", "vsplit", "new" }) do
    local before = #api.nvim_tabpage_list_wins(0)
    local buf = layout ~= "new" and scratch() or nil
    local win = window.open(layout, buf)
    H.eq(#api.nvim_tabpage_list_wins(0), before + 1, layout .. " adds a window")
    H.eq(api.nvim_get_current_win(), win, layout .. " returns the current window")
    if buf then H.eq(api.nvim_win_get_buf(win), buf, layout .. " shows the buffer") end
    H.ok(window.close(win, start_win), layout .. " window is closed")
    H.falsy(api.nvim_win_is_valid(win), layout .. " window is gone")
    api.nvim_set_current_win(start_win)
  end

  -- current reuses the window
  local b = scratch()
  local cur = window.open("current", b)
  H.eq(cur, start_win, "current reuses the current window")
  H.eq(api.nvim_win_get_buf(cur), b, "and shows the buffer in it")

  -- tab opens a new tabpage
  local tab_win = window.open("tab", scratch())
  H.ok(api.nvim_get_current_tabpage() ~= start_tab, "tab opens a new tabpage")
  window.close(tab_win)
  if api.nvim_tabpage_is_valid(start_tab) then api.nvim_set_current_tabpage(start_tab) end

  -- restore_focus goes to the given window, else to the previous one
  local other = window.open("split")
  window.restore_focus(start_win)
  H.eq(api.nvim_get_current_win(), start_win, "restore_focus returns to the given window")
  api.nvim_set_current_win(other)
  window.restore_focus(0)
  H.eq(api.nvim_get_current_win(), start_win, "restore_focus(0) goes to the previous window")

  -- close: a window that is gone, nil and the kept window are left alone
  H.falsy(window.close(nil), "close(nil) does nothing")
  H.falsy(window.close(start_win, start_win), "the kept window is not closed")
  H.ok(api.nvim_win_is_valid(start_win), "and stays")
  H.ok(window.close(other), "a valid window is closed")
  H.falsy(window.close(other), "a window that is gone is not an error")

  for _, nr in ipairs(made_bufs) do
    if api.nvim_buf_is_valid(nr) then api.nvim_buf_delete(nr, { force = true }) end
  end
end
