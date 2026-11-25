-- ~/.config/nvim/init.lua
-- Clean, transparent Neovim setup for Python (Neovim 0.11+)

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

-- Python-friendly indentation
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true

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
                theme = "catppuccin",
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
                "python", "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml", "markdown",
            })
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
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
        },
        config = function()
            vim.lsp.config("pyright", {
                settings = {
                    pyright = { disableOrganizeImports = true }, -- ruff handles imports
                    python = { analysis = { typeCheckingMode = "basic" } },
                },
            })
            vim.lsp.config("lua_ls", {
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
            require("mason-lspconfig").setup({
                ensure_installed = { "pyright", "ruff", "lua_ls" },
                automatic_enable = true,
            })
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

    -- Formatting (ruff)
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                python = { "ruff_organize_imports", "ruff_format" },
            },
            format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
        },
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
    { "folke/which-key.nvim",                event = "VeryLazy",    opts = { preset = "helix" } },
}, {
    ui = { border = "rounded" },
    change_detection = { notify = false },
})

---------------------------------------------------------------------------
-- Extra transparency (covers plugins the theme might miss)
---------------------------------------------------------------------------
for _, group in ipairs({
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn",
    "StatusLine", "StatusLineNC", "TelescopeNormal", "TelescopeBorder",
}) do
    vim.api.nvim_set_hl(0, group, { bg = "none", fg = vim.api.nvim_get_hl(0, { name = group }).fg })
end

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

-- Run the current Python file in a split terminal
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function(ev)
        map("n", "<leader>r", function()
            vim.cmd("w")
            vim.cmd("botright split | resize 12 | terminal python3 " .. vim.fn.shellescape(vim.fn.expand("%")))
        end, { buffer = ev.buf, desc = "Run Python file" })
    end,
})
