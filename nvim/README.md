# Neovim

A single-file config (`init.lua`) for Neovim 0.11+, aimed at Python and kept
transparent so the terminal background — and the wallpaper behind it — shows
through.

## Layout

| File | What it is |
| --- | --- |
| `init.lua` | The whole config: options, plugins, LSP, keymaps. |
| `lazy-lock.json` | Pinned plugin revisions. Commit it; that's the lockfile. |

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which
bootstraps itself on first launch into `~/.local/share/nvim/lazy` — outside
this repo, so nothing plugin-sized lands in git.

## What's in it

* **catppuccin** (mocha, transparent) — plus an explicit pass that clears the
  background on the groups the theme misses, so floats and Telescope stay
  see-through.
* **lualine** — one global statusline; `showmode` off and `cmdheight = 0`.
* **treesitter** (`main` branch) — python, lua, vim, bash, json, yaml, toml,
  markdown. Needs the tree-sitter CLI to build parsers.
* **mason + lspconfig** — auto-installs `pyright`, `ruff` and `lua_ls`.
  Pyright's organise-imports is off; ruff does it.
* **blink.cmp** — completion and signature help, rounded borders.
* **conform** — format on save: ruff organise-imports then ruff format, with
  LSP formatting as fallback.
* **telescope**, **oil**, **gitsigns**, **indent-blankline**, **autopairs**,
  **which-key**.

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
| `<leader>r` (python) | Save and run the file in a split terminal |

With an LSP attached: `gd` definition, `gr` references, `K` hover,
`<leader>rn` rename, `<leader>ca` code action, `<leader>e` diagnostic float.

## Packages

```sh
sudo pacman -S --needed neovim ripgrep fd tree-sitter-cli python-pynvim
```

`ripgrep` and `fd` back Telescope; `tree-sitter-cli` is what treesitter's
`main` branch shells out to when it builds a parser. The language servers
come from mason, not pacman.
