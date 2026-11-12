-- TESTS/sheets/features.lua -- the functionalities of pdfport.nvim as its user meets them; `testing sheets report`
-- says which ones have a feature sheet (`feature = "<id>"`) and in which state, and K16 warns about a sheet that names
-- an id not listed here. Data: read with an empty environment like a sheet (testing.nvim docs/SHEETS.md).
-- The list follows docs/FEATURES/ (README.md and its pages), docs/commands.md and docs/WORKFLOW.md; the registration
-- APIs for plugin authors are not on it.
return {
  {
    id = "pdfport.open",
    title = ":PdfPort asks how to open the PDF: text in a buffer, a float, the system application or a terminal image",
    surface = { "command:PdfPort" },
    docs = "docs/WORKFLOW.md",
  },
  {
    id = "pdfport.text",
    title = ":PdfPort text extracts the PDF into a scratch buffer through the first available backend",
    surface = { "command:PdfPort text" },
    docs = "docs/FEATURES/BACKENDS.md",
  },
  {
    id = "pdfport.float",
    title = ":PdfPort float shows the extracted pages of a range in a centered float",
    surface = { "command:PdfPort float" },
    docs = "docs/FEATURES/RENDERING.md",
  },
  {
    id = "pdfport.system",
    title = ":PdfPort system opens the original PDF with the system application",
    surface = { "command:PdfPort system" },
    docs = "docs/FEATURES/RENDERING.md",
  },
  {
    id = "pdfport.terminal",
    title = ":PdfPort terminal renders pages of a range as images in the terminal",
    surface = { "command:PdfPort terminal" },
    docs = "docs/FEATURES/RENDERING.md",
  },
  {
    id = "pdfport.ai-backends",
    title = "Claude, Gemini or a local Ollama vision model extract a PDF through ai.nvim",
    docs = "docs/FEATURES/BACKENDS.md",
  },
  {
    id = "pdfport.ocr",
    title = "Scanned pages fall back to Tesseract OCR",
    docs = "docs/FEATURES/BACKENDS.md",
  },
  {
    id = "pdfport.cache",
    title = "An extraction is cached across restarts; the same file again is instant",
    docs = "docs/FEATURES/CORE.md",
  },
  {
    id = "pdfport.create",
    title = ":PdfPort create makes a PDF from an image, Markdown, text, HTML or office file",
    surface = { "command:PdfPort create" },
    docs = "docs/FEATURES/PRODUCERS.md",
  },
  {
    id = "pdfport.merge",
    title = ":PdfPort merge joins two or more PDFs into one",
    surface = { "command:PdfPort merge" },
    docs = "docs/FEATURES/PRODUCERS.md",
  },
  {
    id = "pdfport.diagnostics",
    title = ":PdfPort backends, producers and health say what is available on this machine",
    surface = { "command:PdfPort backends", "command:PdfPort producers", "command:PdfPort health" },
    docs = "docs/FEATURES/CORE.md",
  },
  {
    id = "pdfport.file-trees",
    title = "From a file tree the PDF opens in the editor window, never in a neo-tree, nvim-tree or netrw sidebar",
    docs = "docs/FEATURES/INTEGRATIONS.md",
  },
  {
    id = "pdfport.batch-open",
    title = "<leader>pb opens every PDF of the selected lines of a file tree",
    docs = "docs/FEATURES/INTEGRATIONS.md",
  },
  {
    id = "pdfport.picker-preview",
    title = "Telescope and fzf-lua preview a PDF as its extracted text",
    docs = "docs/FEATURES/INTEGRATIONS.md",
  },
}
