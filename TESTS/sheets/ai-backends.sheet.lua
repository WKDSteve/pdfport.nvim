-- Feature sheet: a user with a local Ollama vision model as the backend runs `:PdfPort text`; pdfport
-- rasterizes page 1 (pdftoppm of poppler, real), sends it to the model through ai.nvim and shows the answer,
-- with the notice that only page 1 of 2 was read (pdfinfo, real). With a text model (`mistral`) the page
-- goes as text (pdftotext, real). ai.nvim is a stub (no network in a sheet, docs/SHEETS.md of testing.nvim):
-- it answers with what it was given. `ollama` and `curl` are stand-ins: pdfport only checks they exist.
-- Claude and Gemini go through the same ai.nvim call and start no process of pdfport. Once by hand: a real
-- model on a real daemon or key (manual below).
local S = 'dofile(vim.fn.getcwd() .. "/TESTS/support/sheet.lua")'
local AI_STUB = [[
_G.requests = {}
package.loaded["ai.attachments"] = { from_file = function(p) return { kind = "image", path = p } end }
package.loaded["ai"] = {
  ask = function(req, cb)
    _G.requests[#_G.requests + 1] = req
    local seen = req.attachments and "an image" or (req.prompt:match("content:%s*(%a+ page %a+)") or "?")
    vim.schedule(function() cb(true, { text = "The model read " .. seen }) end)
  end,
}]]
return {
  id = "pdfport.ai-backends",
  feature = "pdfport.ai-backends",
  title = "pdfport: an Ollama vision model reads page 1, a text model gets the page text",
  engine = "rpc",
  sizes = { { rows = 24, cols = 100 } },
  requires = {
    {
      lua = 'vim.fn.executable("pdftoppm") == 1 and vim.fn.executable("pdftotext") == 1',
      reason = "pdftoppm and pdftotext (poppler) are not installed here",
    },
  },
  steps = {
    {
      lua = S
        .. ".project() _G.sheet.stand_ins({ ollama = {}, curl = {} })"
        .. AI_STUB
        .. [[
      _G.sheet.setup({ default_backend = "ollama", ollama_model = "llava", extract_opts = { cache = false } })]],
      note = "a project with doc.pdf; ollama with the vision model llava is the backend, ai.nvim a stub",
    },
    { keys = ":PdfPort text doc.pdf<CR>", note = "extract the PDF" },
    {
      wait = [[_G.sheet.window_with("The model read an image", false) ~= nil and _G.sheet.noted("only page 1 of 2")]],
      timeout = 10000,
      note = "the model's answer on the page image is shown, page 1 of 2",
    },
    {
      expect = [[#_G.requests == 1 and _G.requests[1].provider == "ollama" and _G.requests[1].model == "llava"
        and _G.requests[1].attachments[1].path:find("%.png$") ~= nil]],
      note = "one request to ollama's llava with the PNG of the page",
    },
    {
      lua = [[_G.sheet.setup({ default_backend = "ollama", ollama_model = "mistral", extract_opts = { cache = false } })]],
      note = "the user switches to the text model mistral",
    },
    { keys = ":PdfPort float doc.pdf pages=2<CR>", note = "page 2 in a float" },
    {
      wait = [[_G.sheet.window_with("The model read Beta page two", true) ~= nil]],
      timeout = 10000,
      note = "the model got the text of page 2 and its answer is in the float",
    },
    {
      expect = [[#_G.requests == 2 and _G.requests[2].model == "mistral" and _G.requests[2].attachments == nil]],
      note = "a text request, no image",
    },
  },
  judge = {},
  manual = {
    "with a running ollama daemon and llava pulled: :PdfPort text on a scanned PDF gives the page as Markdown",
    "with a Claude or Gemini key: the same through default_backend = 'claude' / 'gemini'",
  },
}
