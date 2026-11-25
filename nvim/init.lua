-- ~/.config/nvim/init.lua
-- Clean, transparent Neovim setup for Python, Laravel and JS/three.js (Neovim 0.11+)

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt
o.number = true
o.relativenumber = false
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.showmode = false          -- lualine shows the mode
o.laststatus = 3            -- one global statusline
o.cmdheight = 0             -- hide command line when unused
o.fillchars = { eob = " " } -- no ~ at end of buffer
o.scrolloff = 8
o.wrap = false
o.mouse = "a"
o.clipboard = "unnamedplus"
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.undofile = true
o.updatetime = 250

-- 4-space indentation (Python, PHP); web filetypes drop to 2 below
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "html", "css", "scss", "json", "jsonc", "yaml", "vue",
    },
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
    end,
})

-- Blade templates and shader files
vim.filetype.add({
    pattern = { [".*%.blade%.php"] = "blade" },
    extension = { vs = "glsl", fs = "glsl", vert = "glsl", frag = "glsl", glsl = "glsl" },
})

---------------------------------------------------------------------------
-- Plugin manager (lazy.nvim)
---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Theme (transparent)
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                float = { transparent = true, solid = false },
                integrations = {
                    blink_cmp = true,
                    gitsigns = true,
                    mason = true,
                    telescope = { enabled = true },
                    which_key = true,
                    indent_blankline = { enabled = true },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "catppuccin-nvim",
                globalstatus = true,
                component_separators = "",
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "diagnostics", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- Syntax highlighting (needs the tree-sitter CLI installed)
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({
                "python", "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
                "markdown", "markdown_inline", "regex", "sql", "dockerfile", "gitignore", "diff",
                "php", "php_only", "phpdoc", "blade", "html", "css", "scss",
                "javascript", "typescript", "tsx", "jsdoc", "glsl",
            })
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(ev)
                    if pcall(vim.treesitter.start) and ev.match ~= "python" then
                        -- treesitter indent is much better than smartindent for PHP/JS/HTML
                        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },

    -- LSP: installer + servers
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
            "neovim/nvim-lspconfig",
            "b0o/SchemaStore.nvim",
        },
        config = function()
            vim.lsp.config("pyright", {
                -- use the project's .venv when there is one
                before_init = function(_, config)
                    local py = config.root_dir and config.root_dir .. "/.venv/bin/python"
                    if py and vim.uv.fs_stat(py) then
                        config.settings.python.pythonPath = py
                    end
                end,
                settings = {
                    pyright = { disableOrganizeImports = true }, -- ruff handles imports
                    python = { analysis = { typeCheckingMode = "basic" } },
                },
            })
            vim.lsp.config("lua_ls", {
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
            vim.lsp.config("jsonls", {
                settings = {
                    json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
                },
            })
            -- HTML/emmet inside Blade templates too
            vim.lsp.config("html", { filetypes = { "html", "blade" } })
            vim.lsp.config("emmet_language_server", {
                filetypes = {
                    "html", "blade", "css", "scss", "javascriptreact", "typescriptreact", "vue",
                },
            })
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "pyright", "ruff", "lua_ls",
                    "intelephense",    -- PHP / Laravel
                    "ts_ls", "eslint", -- JS/TS (gsap, three)
                    "html", "cssls", "jsonls", "emmet_language_server", "tailwindcss",
                    "glsl_analyzer",   -- shaders
                },
                automatic_enable = true,
            })

            -- Formatters (not LSPs, so mason-lspconfig doesn't install them)
            local registry = require("mason-registry")
            registry.refresh(function()
                for _, name in ipairs({ "prettierd", "blade-formatter", "pint" }) do
                    local ok, pkg = pcall(registry.get_package, name)
                    if ok and not pkg:is_installed() then pkg:install() end
                end
            end)
        end,
    },

    -- Autocompletion
    {
        "saghen/blink.cmp",
        version = "1.*",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = { preset = "default" }, -- <C-y> accept, <C-n>/<C-p> navigate
            appearance = { nerd_font_variant = "mono" },
            completion = {
                menu = { border = "rounded" },
                documentation = { auto_show = true, window = { border = "rounded" } },
            },
            signature = { enabled = true, window = { border = "rounded" } },
        },
    },

    -- Formatting: ruff (python), pint (php), blade-formatter, prettier (web)
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = function()
            local prettier = { "prettierd", "prettier", stop_after_first = true }
            local by_ft = {
                python = { "ruff_organize_imports", "ruff_format" },
                php = { "pint" },
                blade = { "blade-formatter" },
            }
            for _, ft in ipairs({
                "javascript", "javascriptreact", "typescript", "typescriptreact", "vue",
                "html", "css", "scss", "json", "jsonc", "yaml", "markdown",
            }) do
                by_ft[ft] = prettier
            end
            return {
                formatters_by_ft = by_ft,
                -- pint boots PHP on every save, so give it more headroom
                format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
            }
        end,
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Telescope",
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
            { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
        },
    },

    -- File explorer (edit directories like a buffer)
    {
        "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
        opts = { view_options = { show_hidden = true } },
        keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent directory" } },
    },

    -- Small niceties
    { "lewis6991/gitsigns.nvim",             opts = {} },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl",          opts = { scope = { enabled = false } } },
    { "windwp/nvim-autopairs",               event = "InsertEnter", opts = {} },
    { "windwp/nvim-ts-autotag",              event = "InsertEnter", opts = {} }, -- close/rename HTML & Blade tags
    { "folke/which-key.nvim",                event = "VeryLazy",    opts = { preset = "helix" } },
}, {
    ui = { border = "rounded" },
    change_detection = { notify = false },
})

---------------------------------------------------------------------------
-- Extra transparency (covers plugins the theme might miss)
---------------------------------------------------------------------------
local function clear_backgrounds()
    for _, group in ipairs({
        "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn",
        "StatusLine", "StatusLineNC", "TelescopeNormal", "TelescopeBorder",
    }) do
        vim.api.nvim_set_hl(0, group, { bg = "none", fg = vim.api.nvim_get_hl(0, { name = group }).fg })
    end
end
clear_backgrounds()

---------------------------------------------------------------------------
-- :white / :dark  -> switch between light (latte) and transparent dark (mocha)
---------------------------------------------------------------------------
local function set_theme(light)
    require("catppuccin").setup({
        flavour = light and "latte" or "mocha",
        transparent_background = not light,
        float = { transparent = not light, solid = false },
        integrations = {
            blink_cmp = true,
            gitsigns = true,
            mason = true,
            telescope = { enabled = true },
            which_key = true,
            indent_blankline = { enabled = true },
        },
    })
    vim.o.background = light and "light" or "dark"
    vim.cmd.colorscheme("catppuccin")
    if not light then clear_backgrounds() end
end
vim.api.nvim_create_user_command("White", function() set_theme(true) end, { desc = "Light mode" })
vim.api.nvim_create_user_command("Dark", function() set_theme(false) end, { desc = "Dark mode" })
-- allow lowercase :white / :dark
vim.cmd([[cnoreabbrev <expr> white getcmdtype() == ':' && getcmdline() ==# 'white' ? 'White' : 'white']])
vim.cmd([[cnoreabbrev <expr> dark getcmdtype() == ':' && getcmdline() ==# 'dark' ? 'Dark' : 'dark']])

---------------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------------
vim.diagnostic.config({
    virtual_text = { prefix = "●" },
    severity_sort = true,
    float = { border = "rounded" },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
    },
})

---------------------------------------------------------------------------
-- Keymaps
---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line up" })

-- LSP keymaps (only active when a server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = function(desc) return { buffer = ev.buf, desc = desc } end
        map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        map("n", "gr", "<cmd>Telescope lsp_references<cr>", opts("References"))
        map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, opts("Hover"))
        map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
        map("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        map("n", "<leader>e", vim.diagnostic.open_float, opts("Show diagnostic"))
    end,
})

-- Run a command in a split terminal at the bottom
local function term(cmd)
    vim.cmd("botright split | resize 12 | terminal " .. cmd)
end

-- Run the current file (python uses the project's .venv when there is one)
local runners = {
    python = function()
        local venv = vim.fs.root(0, ".venv")
        return venv and venv .. "/.venv/bin/python" or "python3"
    end,
    javascript = function() return "node" end,
    php = function() return "php" end,
}
vim.api.nvim_create_autocmd("FileType", {
    pattern = vim.tbl_keys(runners),
    callback = function(ev)
        map("n", "<leader>r", function()
            vim.cmd("w")
            term(runners[ev.match]() .. " " .. vim.fn.shellescape(vim.fn.expand("%")))
        end, { buffer = ev.buf, desc = "Run file" })
    end,
})

-- Laravel: run an artisan command from the project root
map("n", "<leader>a", function()
    local root = vim.fs.root(0, "artisan")
    if not root then return vim.notify("Not in a Laravel project", vim.log.levels.WARN) end
    vim.ui.input({ prompt = "artisan " }, function(args)
        if args and args ~= "" then term("cd " .. vim.fn.shellescape(root) .. " && php artisan " .. args) end
    end)
end, { desc = "Artisan command" })

-- Project dev server (vite for gsap/three, or anything in package.json)
map("n", "<leader>n", function() term("npm run dev") end, { desc = "npm run dev" })

---------------------------------------------------------------------------
-- Zoom: Ctrl +  /  Ctrl -  /  Ctrl 0   (GUI only: Neovide, nvim-qt, ...)
-- In a plain terminal, use the terminal emulator's own zoom instead.
---------------------------------------------------------------------------
local font_family = "JetBrainsMono Nerd Font" -- change to your font
local default_size = 14
local font_size = default_size

if not vim.g.neovide then
    vim.o.guifont = font_family .. ":h" .. font_size
end

local function zoom(delta)
    if vim.g.neovide then
        -- Neovide scales everything smoothly
        local scale = (vim.g.neovide_scale_factor or 1.0) * (delta > 0 and 1.1 or 1 / 1.1)
        vim.g.neovide_scale_factor = math.min(math.max(scale, 0.4), 5.0)
    else
        font_size = math.min(math.max(font_size + delta, 6), 48)
        vim.o.guifont = font_family .. ":h" .. font_size
    end
end

local function zoom_reset()
    if vim.g.neovide then
        vim.g.neovide_scale_factor = 1.0
    else
        font_size = default_size
        vim.o.guifont = font_family .. ":h" .. font_size
    end
end

for _, key in ipairs({ "<C-+>", "<C-=>", "<C-ScrollWheelUp>" }) do
    map({ "n", "v", "i" }, key, function() zoom(1) end, { desc = "Zoom in" })
end
for _, key in ipairs({ "<C-->", "<C-ScrollWheelDown>" }) do
    map({ "n", "v", "i" }, key, function() zoom(-1) end, { desc = "Zoom out" })
end
map({ "n", "v", "i" }, "<C-0>", zoom_reset, { desc = "Reset zoom" })
