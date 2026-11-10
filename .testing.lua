-- .testing.lua -- configuration of testing.nvim for this project.
-- Written by `testing migrate`; edit freely (it is never overwritten). Every key is optional; the
-- keys are documented in testing.nvim's docs/CONFIG.md. Loading this file executes it (same trust
-- as running the specs).
-- lib.nvim opens a one-time "missing tools" welcome float (deps.first_run) from setup() on a machine
-- without its seen-marker, i.e. on every fresh CI runner. It runs from a scheduled callback and would
-- take over the current window during a later spec (picker_batch_spec: "Invalid buffer id"). The
-- specs do not test it, so it is switched off for the run.
vim.g.lib_nvim_deps_disable_first_run = true

return {
  -- Lua module root of the project.
  plugin = "pdfport",
  -- How the spec files are run: "auto" = sniffed per file, "h" = on the project's own TESTS/harness.lua,
  -- "script" = a self-running script in its own process.
  -- TESTS/sheets_spec.lua is busted style: one case per test sheet (`sheet:<id>`, testing sheets report).
  dialect = { ["TESTS/sheets_spec.lua"] = "busted", ["*"] = "h" },
  -- Dependencies (directory names) put on the runtimepath: $<NAME>_DIR, .deps/<name>, ../<name>,
  -- stdpath('data')/lazy/<name>.
  deps = { "lib.nvim" },
  -- "none" = all specs in one nvim, "file" = one nvim per spec file
  -- (nothing leaks from one file into the next).
  -- "file": setup() registers :PdfPort and several specs leave pdfport:// buffers or a lib.nvim
  -- which_key autocmd behind; one editor per file keeps all of that from reaching the next spec.
  -- Every spec builds its own fixtures (health_spec stubs the registry and the composer route
  -- check), so a single file also runs alone (`--file`, `--shard`, `--watch`).
  isolated = "file",
  -- Guards (docs/GUARDS.md of testing.nvim). The suite is clean on all of them.
  guards = {
    fs = "error",
    state = "error",
    scheduled_error = "error",
    prompt = "error",
    deprecation = "error",
    -- The specs probe external tools on purpose (see guard_allow.spawn).
    process_net = "error",
  },
  guard_allow = {
    spawn = {
      -- registry_spec probes the optional python packages (pdfplumber, docling) via `python3 -c import`.
      "python3",
      -- ai_backends_spec checks the argv of the pdftotext backend against a missing file.
      "pdftotext",
      -- sheets_spec.lua: every test sheet (TESTS/sheets/) runs in a child editor.
      "nvim",
    },
  },
  -- Environment variables the specs read; a child editor inherits an allowlist only (never secrets).
  env_allow = { "MAGICK_*" },
  -- The runner counts which commands, keymaps and autocommands the specs exercise (docs/SURFACE.md of testing.nvim);
  -- `scripts/test.sh surface` compares that with surface.baseline.json (a regression gate, not a percentage).
  surface = { track = true },
  -- gated: a failed conformance check makes `scripts/test.sh conformance` exit 1 (docs/CONFORMANCE.md of testing.nvim)
  conformance = {
    gate = true,
    waivers = {
      {
        check = "K6",
        level = "warn",
        text = "API_KEY not set",
        reason = "optional LLM backend: its API key is not set in the minimal editor (the backend is opt-in and reports itself unavailable by design)",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING claude",
        reason = "optional LLM backend: its API key is not set in the minimal editor (the backend is opt-in and reports itself unavailable by design)",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING gemini",
        reason = "optional LLM backend: its API key is not set in the minimal editor (the backend is opt-in and reports itself unavailable by design)",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING ollama",
        reason = "optional ollama backend: no ollama daemon runs in the minimal editor, the health check correctly reports it unavailable",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING docling",
        reason = "optional Python converter (not installed in the minimal editor/CI image): the health check correctly reports the missing module",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING pdfplumber",
        reason = "optional Python converter (not installed in the minimal editor/CI image): the health check correctly reports the missing module",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING img2pdf",
        reason = "optional external PDF tool not on PATH in the minimal editor/CI image: the health check correctly reports the missing producer",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING pandoc",
        reason = "optional external PDF tool not on PATH in the minimal editor/CI image: the health check correctly reports the missing producer",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING pdftk",
        reason = "optional external PDF tool not on PATH in the minimal editor/CI image: the health check correctly reports the missing producer",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING qpdf",
        reason = "optional external PDF tool not on PATH in the minimal editor/CI image: the health check correctly reports the missing producer",
        expires = "2027-04-14",
      },
      {
        check = "K6",
        level = "warn",
        text = "WARNING weasyprint",
        reason = "optional external PDF tool not on PATH in the minimal editor/CI image: the health check correctly reports the missing producer",
        expires = "2027-04-14",
      },
    },
  },
  -- The pipeline is derived (`scripts/test.sh ci list`). The GitHub workflow is generated from `workflow`:
  -- `testing init --workflow=public --force` writes it (testing.nvim docs/WORKFLOW-CI.md), the step
  -- workflow-in-sync checks it.
  ci = {
    workflow = {
      name = "pdfport.nvim",
      layout = "hosted",
      -- the steps that depend on the platform: the windows and macOS legs run only these
      platform = { "suite", "conformance" },
      -- the real file trees of the sidebar test sheets (TESTS/support/trees.lua finds them in .deps)
      checkouts = {
        {
          repo = "nvim-neo-tree/neo-tree.nvim",
          ref = "1a14083046d96e88e361d1da00761c40d45012f3",
          why = "A real file tree of the sidebar test sheets (TESTS/sheets/sidebar-*.sheet.lua).",
        },
        {
          repo = "MunifTanjim/nui.nvim",
          ref = "10fc361835c856ba4233ef5ea135b919bf3dce97",
          why = "The same sidebar test sheets.",
        },
        {
          repo = "nvim-lua/plenary.nvim",
          ref = "74b06c6c75e4eeb3108ec01852001636d85a932b",
          why = "The same sidebar test sheets.",
        },
        {
          repo = "nvim-tree/nvim-web-devicons",
          ref = "58447c1fca354bbf184425e4a8d01deecbd6f3c4",
          why = "The same sidebar test sheets.",
        },
        {
          repo = "nvim-tree/nvim-tree.lua",
          ref = "9a2e0006d42f292eb3ade7dfdff201a7429a780c",
          why = "The same sidebar test sheets.",
        },
        {
          repo = "stevearc/oil.nvim",
          ref = "17c0a8faaf48298a0c0cfb0d757c0eaee4ff7a32",
          why = "The same sidebar test sheets.",
        },
      },
      packages = {
        { name = "poppler", apt = "poppler-utils", why = "pdftotext, a real dependency of the extraction specs" },
      },
      -- `testing ci land`: a check branch ci/** runs the hosted legs, main moves only once it is green there
      land = true,
    },
    steps = {
      ["workflow-in-sync"] = { preset = "workflow-in-sync" },
    },
  },
}
