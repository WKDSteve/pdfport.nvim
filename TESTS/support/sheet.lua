-- TESTS/support/sheet.lua -- helpers of the feature sheets (TESTS/sheets/*.sheet.lua).
--
-- Loaded INSIDE the child editor of a sheet (`dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")`): sheets
-- are data and cannot require anything while they are read. It builds the user's starting point (a project
-- with a small two-page PDF), records what pdfport tells the user, and puts recording stand-ins
-- (testing.fake_programs) in front of the optional converters (tesseract, the producers, chafa, ...).
--
-- poppler (pdftotext, pdftoppm, pdfinfo) always runs for real: it is light on a two-page PDF, and the CI legs
-- install it on every system. Everything else is a stand-in. With stand-ins the PATH is cut down to the
-- stand-ins and poppler's own folders, so a real converter of this machine (soffice, magick, Ghostscript,
-- a browser) can never run in a sheet, also not where a name is looked up the way libuv does it.

local S = {}

S.PAGES = { "Alpha page one", "Beta page two" }

---Write a minimal PDF with one line of Helvetica text per page (`pages`), with a correct xref table.
---@param path string
---@param pages string[]
function S.write_pdf(path, pages)
  local objs = {}
  local n = #pages
  -- 1 catalog, 2 pages, 3 font, then per page: page object and its content stream
  local kids = {}
  for i = 1, n do
    kids[#kids + 1] = ("%d 0 R"):format(2 + 2 * i)
  end
  objs[1] = "<< /Type /Catalog /Pages 2 0 R >>"
  objs[2] = ("<< /Type /Pages /Kids [%s] /Count %d >>"):format(table.concat(kids, " "), n)
  objs[3] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
  for i, text in ipairs(pages) do
    local stream = ("BT /F1 24 Tf 72 720 Td (%s) Tj ET"):format(text)
    objs[2 + 2 * i] = ("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>"):format(
      3 + 2 * i
    )
    objs[3 + 2 * i] = ("<< /Length %d >>\nstream\n%s\nendstream"):format(#stream, stream)
  end
  local out = { "%PDF-1.4\n" }
  local offsets, size = {}, #out[1]
  for i = 1, #objs do
    offsets[i] = size
    local obj = ("%d 0 obj\n%s\nendobj\n"):format(i, objs[i])
    out[#out + 1] = obj
    size = size + #obj
  end
  local xref = { ("xref\n0 %d\n0000000000 65535 f \n"):format(#objs + 1) }
  for i = 1, #objs do
    xref[#xref + 1] = ("%010d 00000 n \n"):format(offsets[i])
  end
  out[#out + 1] = table.concat(xref)
  out[#out + 1] = ("trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n"):format(
    #objs + 1,
    size
  )
  local fd = assert(io.open(path, "wb"))
  fd:write(table.concat(out))
  fd:close()
end

---A project as the user has it: `doc.pdf` (two pages, `S.PAGES`) and `notes.md` naming it, open in the one
---window, the working directory at the project. No intro message, a command line tall enough for a
---notification with a temporary path (no hit-enter prompt).
---`root` (optional) is a folder that outlives a restart of the child (below `stdpath("data")`; the editor's
---own temporary folder is removed when it quits); files already there are kept as they are.
---@param root? string
---@return string root
function S.project(root)
  vim.opt.shortmess:append("I")
  vim.o.cmdheight = 4
  root = vim.fs.normalize(root or vim.fn.tempname())
  vim.fn.mkdir(root, "p")
  if vim.fn.filereadable(root .. "/doc.pdf") == 0 then
    S.write_pdf(root .. "/doc.pdf", S.PAGES)
    vim.fn.writefile({ "# Notes", "", "See doc.pdf for the details." }, root .. "/notes.md")
  end
  vim.cmd.cd(vim.fn.fnameescape(root))
  vim.cmd.edit("notes.md")
  _G.sheet, _G.sheet_root = S, root
  _G.editor_win = vim.api.nvim_get_current_win()
  S.listen()
  return root
end

---Record every notification (pdfport reports through vim.notify) in `_G.notes`; they still reach the screen.
function S.listen()
  _G.notes = {}
  local orig = vim.notify
  vim.notify = function(msg, level, opts)
    _G.notes[#_G.notes + 1] = tostring(msg)
    return orig(msg, level, opts)
  end
end

---Was a notification containing `text` (plain) shown?
---@param text string
---@return boolean
function S.noted(text)
  for _, m in ipairs(_G.notes or {}) do
    if m:find(text, 1, true) then return true end
  end
  return false
end

---pdfport's setup as a user writes it, without the one-time "optional tools" popup of lib.nvim.deps.
---@param cfg? table
function S.setup(cfg)
  require("pdfport").setup(vim.tbl_deep_extend("force", { deps_popup = false }, cfg or {}))
end

---The lines of buffer `buf` as one string.
---@param buf integer
---@return string
function S.text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

---The first window of the tab whose buffer contains `text` (plain), or nil.
---@param text string
---@param want_float? boolean  only floating windows (true) or only normal ones (false)
---@return integer|nil
function S.window_with(text, want_float)
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local float = vim.api.nvim_win_get_config(w).relative ~= ""
    if want_float == nil or want_float == float then
      if S.text(vim.api.nvim_win_get_buf(w)):find(text, 1, true) then return w end
    end
  end
  return nil
end

---Folders that hold the named real programs (poppler's tools), deduplicated.
---@param names string[]
---@return string[]
local function dirs_of(names)
  local seen, out = {}, {}
  for _, n in ipairs(names) do
    local exe = vim.fn.exepath(n)
    if exe ~= "" then
      local d = vim.fs.dirname(vim.fs.normalize(exe))
      if not seen[d:lower()] then
        seen[d:lower()] = true
        out[#out + 1] = d
      end
    end
  end
  return out
end

---Programs pdfport starts through vim.system, vim.fn.system or jobstart, which resolve a name like `exepath()`
---(the first folder of the PATH with any PATHEXT wins, so the stand-in in front does).
local EXEPATH_NAMES = { curl = true, ["xdg-open"] = true, chafa = true, ollama = true }

---Stand-ins for `programs` (`{ name = { stdout = ..., exit_code = ... } }`), first on a PATH that holds only
---them and the folders of poppler (and on Windows the system folder, for cmd.exe). On Windows it raises when a
---kept folder also holds a real `<name>.exe` of a stand-in that pdfport starts through libuv: libuv skips the
---`.cmd` stand-in and would run that one. A browser or LibreOffice of lib.nvim.deps' install paths is never
---reached: the stand-in's name is found first (and the install paths are only checked, never started).
---@param programs table<string, table>
---@return table fake  testing.fake_programs instance, also `_G.fake`
function S.stand_ins(programs)
  local fake = require("testing.fake_programs").new(programs)
  local windows = vim.fn.has("win32") == 1
  local keep = dirs_of({ "pdftotext", "pdftoppm", "pdfinfo" })
  if windows then
    keep[#keep + 1] = vim.fs.normalize((vim.env.SystemRoot or "C:/Windows") .. "/System32")
  else
    -- sh, printf and the rest of a POSIX stand-in
    for _, d in ipairs({ "/usr/bin", "/bin" }) do
      keep[#keep + 1] = d
    end
  end
  for name in pairs(windows and programs or {}) do
    for _, d in ipairs(EXEPATH_NAMES[name] and {} or keep) do
      for _, ext in ipairs({ ".exe", ".com" }) do
        if vim.fn.filereadable(d .. "/" .. name .. ext) == 1 then
          error(("sheet: %s/%s%s would run instead of the stand-in"):format(d, name, ext))
        end
      end
    end
  end
  local sep = windows and ";" or ":"
  local parts = {}
  for _, d in ipairs(keep) do
    parts[#parts + 1] = windows and d:gsub("/", "\\") or d
  end
  -- only PATH changes: poppler's fontconfig keeps its font cache below LOCALAPPDATA (an empty one is rebuilt
  -- from every font of the system, which takes minutes)
  vim.env.PATH = fake:path(table.concat(parts, sep))
  _G.fake = fake
  return fake
end

---The recorded calls of stand-in `name` (`{ program, argv, cwd }` each).
---@param name string
---@return table[]
function S.calls(name)
  return require("testing.fake_programs").read(_G.fake.dir, name)
end

---libuv (lib.nvim.cross.uv.spawn_capture, a raw uv.spawn) looks a bare name up as `.exe`/`.com` only, so on
---Windows a `.cmd` stand-in is not found there: the start is made and fails (ENOENT). True where it runs.
---@return boolean
function S.uv_reaches_stand_ins()
  return vim.fn.has("win32") == 0
end

---Was the program `prog`, started through libuv, asked at least `n` times? Where libuv reaches the stand-in,
---its recorded calls say so (only those whose first argument matches `first`, a Lua pattern, when given: the
---same program may also be started another way); on Windows, the notification of the failed start does
---(`failed to spawn: <prog>`, lib.nvim.cross.uv.spawn_capture): the start was made, the stand-in only cannot
---answer it.
---@param prog string
---@param n? integer  default 1
---@param first? string
---@return boolean
function S.asked(prog, n, first)
  n = n or 1
  if S.uv_reaches_stand_ins() then
    local hits = 0
    for _, c in ipairs(S.calls(prog)) do
      if not first or (c.argv[1] or ""):find(first) then hits = hits + 1 end
    end
    return hits >= n
  end
  local hits = 0
  for _, m in ipairs(_G.notes or {}) do
    if m:find("failed to spawn: " .. prog, 1, true) then hits = hits + 1 end
  end
  return hits >= n
end

return S
