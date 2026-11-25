# Neovim

A single-file config (`init.lua`) for Neovim 0.11+, aimed at Python, PHP/Laravel
and JS/TS (GSAP, three.js, shaders), and kept transparent so the terminal background — and the wallpaper behind it — shows
through.

## Layout

| File | What it is |
| --- | --- |
| `init.lua` | The whole config: options, plugins, LSP, keymaps. |
| `lazy-lock.json` | Pinned plugin revisions. Commit it; that's the lockfile. |
| `queries/{javascript,typescript}/injections.scm` | Highlights GLSL inside `/* glsl */` template strings and `` glsl`…` `` tags. |

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which
bootstraps itself on first launch into `~/.local/share/nvim/lazy` — outside
this repo, so nothing plugin-sized lands in git.

## What's in it

* **catppuccin** (mocha, transparent) — plus an explicit pass that clears the
  background on the groups the theme misses, so floats and Telescope stay
  see-through.
* **lualine** — one global statusline; `showmode` off and `cmdheight = 0`.
* **treesitter** (`main` branch) — python, php, blade, html, css/scss,
  javascript/typescript/tsx, glsl, sql, lua, bash, json, yaml, toml, markdown
  and a few more. Treesitter indent is on for everything but Python. Needs the
  tree-sitter CLI to build parsers.
* **mason + lspconfig** — auto-installs:
  * Python: `pyright` (uses the project's `.venv` when there is one) and `ruff`.
  * PHP/Laravel: `intelephense`.
  * Web: `ts_ls`, `eslint`, `html`, `cssls`, `jsonls` (with SchemaStore, so
    `package.json`/`composer.json`/`tsconfig.json` get validated),
    `emmet_language_server` and `tailwindcss`. html and emmet also run in Blade.
  * Shaders: `glsl_analyzer` (`.glsl`, `.vert`, `.frag`, `.vs`, `.fs`).
  * Lua: `lua_ls`.

  Pyright's organise-imports is off; ruff does it.
* **blink.cmp** — completion and signature help, rounded borders.
* **conform** — format on save, with LSP formatting as fallback:
  ruff (Python), pint (PHP; prefers the project's `vendor/bin/pint`),
  blade-formatter (Blade), prettierd/prettier (JS/TS, HTML, CSS, JSON, YAML,
  Markdown). The formatters are installed by mason too.
* **telescope**, **oil**, **gitsigns**, **indent-blankline**, **autopairs**,
  **ts-autotag** (closes/renames HTML and Blade tags), **which-key**.

Indentation is 4 spaces (Python, PHP, Blade) and 2 for JS/TS, HTML, CSS,
JSON and YAML.

## Keymaps

Leader is <kbd>Space</kbd>.

| Bind | Action |
| --- | --- |
| `<leader>ff` / `fg` / `fb` / `fd` | Find files / grep / buffers / diagnostics |
| `-` | Open parent directory in oil |
| `<leader>w` / `<leader>q` | Save / quit |
| `<Esc>` | Clear search highlight |
| `<C-h/j/k/l>` | Move between splits |
| `J` / `K` (visual) | Move the selection down / up |
| `<leader>r` | Save and run the file (python / node / php) in a split terminal |
| `<leader>a` | Prompt for an `artisan` command and run it from the Laravel root |
| `<leader>n` | `npm run dev` in a split terminal (vite, for gsap/three projects) |

With an LSP attached: `gd` definition, `gr` references, `K` hover,
`<leader>rn` rename, `<leader>ca` code action, `<leader>e` diagnostic float.

## Packages

```sh
sudo pacman -S --needed neovim ripgrep fd tree-sitter-cli python-pynvim
```

`ripgrep` and `fd` back Telescope; `tree-sitter-cli` is what treesitter's
`main` branch shells out to when it builds a parser. The language servers
and formatters come from mason, not pacman, but need `node`/`npm` (most of
them) and `php`/`composer` (pint) on the `PATH`.

For three.js completions, the project should have `three` and `@types/three`
in `node_modules` (`npm i three && npm i -D @types/three`); GSAP ships its own
types. For Laravel's facades and magic models, add
[laravel-ide-helper](https://github.com/barryvdh/laravel-ide-helper) to the
project so intelephense can see them.
