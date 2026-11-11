-- shinrai · Neovim (0.12+)
--
-- Minimal and monochrome. Everything here is built into Neovim; plugins are
-- optional and go in lua/plugins.lua (Neovim's own vim.pack manages them).
--
--   Space f   find a file (fuzzy, as you type)   Space b   switch buffer
--   Space /   search the project (ripgrep)       -         file explorer
--   Space d   the diagnostic under the cursor    gd        go to definition
--   (with the plugins in lua/plugins.lua, Space f / b / / and - get nicer
--   versions, plus Space h help, ]h [h git changes, Space g… git actions)
--   K hover · grn rename · gra code action · grr references (Neovim defaults)
--   Tab / Shift+Tab   walk the completion menu, which opens as you type
--
-- Language servers start by themselves for the ones you've installed
-- (lua-language-server, basedpyright / pyright, typescript-language-server,
-- clangd, rust-analyzer, gopls, bash-language-server, qmlls). :checkhealth
-- vim.lsp shows what's running.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---- look ----
vim.o.termguicolors = true
vim.cmd.colorscheme("shinrai")

vim.o.number = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.laststatus = 3          -- one statusline for the whole window
vim.o.showmode = false        -- the statusline shows the mode
vim.o.ruler = false
vim.o.winborder = "rounded"   -- floating windows (hover, diagnostics)
vim.o.pumborder = "rounded"   -- the completion menu
vim.o.pumheight = 10
vim.o.pummaxwidth = 60
vim.o.fillchars = "eob: ,fold: ,vert:│"
vim.o.list = true
vim.o.listchars = "tab:  ,trail:·,nbsp:␣"
vim.opt.shortmess:append("Ic")  -- no intro screen, no completion chatter
vim.o.wrap = false
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- ---- editing ----
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.smartindent = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"   -- the system clipboard (wl-clipboard)
vim.o.undofile = true
vim.o.swapfile = false
vim.o.confirm = true
vim.o.updatetime = 250
vim.o.timeoutlen = 400

-- ---- statusline ----
--   ( normal )  ~/dots/config/ init.lua ●          ● 2  lua  12:4  Top
local modes = {
    n = "normal", no = "pending", nt = "normal",
    v = "visual", V = "v-line", ["\22"] = "v-block",
    s = "select", S = "s-line", ["\19"] = "s-block",
    i = "insert", ic = "insert", ix = "insert",
    R = "replace", Rv = "replace",
    c = "command", cv = "ex", r = "prompt", rm = "more", ["r?"] = "confirm",
    ["!"] = "shell", t = "terminal",
}

local function escape(text)
    return (text:gsub("%%", "%%%%"))
end

function _G.shinrai_statusline()
    local mode = vim.api.nvim_get_mode().mode
    local label = modes[mode] or modes[mode:sub(1, 1)] or mode

    local name = vim.api.nvim_buf_get_name(0)
    local path = name == "" and "[no name]" or vim.fn.fnamemodify(name, ":~:.")
    if vim.bo.buftype == "terminal" then path = "terminal" end
    local dir, file = path:match("^(.*/)([^/]+)$")
    if not dir then dir, file = "", path end

    local out = {
        -- the mode, in a small white pill like the island
        "%#ShinraiModeEdge#\u{e0b6}%#ShinraiMode#", label, "%#ShinraiModeEdge#\u{e0b4}",
        "  %#ShinraiDim#", escape(dir), "%#ShinraiFile#", escape(file),
        vim.bo.modified and "%#ShinraiSoft# ●" or "",
        vim.bo.readonly and "%#ShinraiDim# ro" or "",
        "%=",
    }

    local counts = vim.diagnostic.count(0)
    local errors = counts[vim.diagnostic.severity.ERROR] or 0
    local warnings = counts[vim.diagnostic.severity.WARN] or 0
    if errors > 0 then out[#out + 1] = "%#ShinraiError#● " .. errors .. "  " end
    if warnings > 0 then out[#out + 1] = "%#ShinraiWarn#● " .. warnings .. "  " end
    if vim.bo.filetype ~= "" then out[#out + 1] = "%#ShinraiDim#" .. vim.bo.filetype .. "  " end
    out[#out + 1] = "%#ShinraiSoft#%l:%c  %#ShinraiDim#%P "

    return table.concat(out)
end

vim.o.statusline = "%!v:lua.shinrai_statusline()"

-- ---- completion as you type ----
-- From the language server when one is attached ("o"), then words from this
-- and other buffers.
vim.o.autocomplete = true
vim.o.complete = "o,.^5,w^5,b^5,u^5"
vim.o.completeopt = "menuone,noselect,popup,fuzzy"

-- ---- command line: suggestions as you type ----
vim.o.wildmode = "noselect:lastused,full"
vim.o.wildoptions = "pum,fuzzy"

-- ---- :find as a fuzzy file picker (Space f) ----
local files = nil

local function list_files()
    if vim.fn.executable("fd") == 1 then
        return vim.fn.systemlist({ "fd", "--type", "f", "--hidden", "--exclude", ".git", "--color", "never" })
    elseif vim.fn.executable("rg") == 1 then
        return vim.fn.systemlist({ "rg", "--files", "--hidden", "--glob", "!.git" })
    end
    local found = vim.fn.globpath(".", "**", true, true)
    found = vim.tbl_filter(function(f) return vim.fn.isdirectory(f) == 0 end, found)
    return vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ":.") end, found)
end

function _G.shinrai_find(arg, _)
    files = files or list_files()
    if arg == "" then return files end
    return vim.fn.matchfuzzy(files, arg)
end

vim.o.findfunc = "v:lua.shinrai_find"

-- ---- project search (Space /) with ripgrep ----
if vim.fn.executable("rg") == 1 then
    vim.o.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git"
    vim.o.grepformat = "%f:%l:%c:%m"
end

-- ---- file explorer (-) ----
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]   -- dotfiles hidden; gh shows them

-- ---- diagnostics: quiet until you're on the line ----
vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    virtual_text = { current_line = true, spacing = 2, prefix = "" },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "●",
            [vim.diagnostic.severity.WARN] = "●",
            [vim.diagnostic.severity.INFO] = "●",
            [vim.diagnostic.severity.HINT] = "·",
        },
    },
    float = { source = "if_many" },
})

-- ---- language servers: only the ones that are installed ----
local function first_executable(names)
    for _, name in ipairs(names) do
        if vim.fn.executable(name) == 1 then return name end
    end
end

local servers = {
    lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
                telemetry = { enable = false },
            },
        },
    },
    basedpyright = {
        cmd = { "basedpyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
    },
    pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
    },
    ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    },
    clangd = {
        cmd = { "clangd" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_markers = { "compile_commands.json", ".clangd", ".git" },
    },
    rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", ".git" },
    },
    gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork" },
        root_markers = { "go.mod", "go.work", ".git" },
    },
    bashls = {
        cmd = { "bash-language-server", "start" },
        filetypes = { "sh", "bash" },
        root_markers = { ".git" },
    },
    qmlls = {   -- Qt's QML server, handy for the Quickshell config
        cmd = { first_executable({ "qmlls6", "qmlls", "/usr/lib/qt6/bin/qmlls" }) or "qmlls" },
        filetypes = { "qml", "qmljs" },
        root_markers = { ".qmlls.ini", ".git" },
    },
}

for name, config in pairs(servers) do
    local skip = name == "pyright" and vim.fn.executable("basedpyright-langserver") == 1
    if not skip and vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
    end
end

-- ---- plugin commands (the plugins themselves load at the end of this file) ----
local function plugin_names()
    return vim.iter(vim.pack.get()):map(function(p) return p.spec.name end):totable()
end

-- :PackUpdate [names]   download updates and show what changed; :write applies, :quit skips
vim.api.nvim_create_user_command("PackUpdate", function(cmd)
    vim.pack.update(#cmd.fargs > 0 and cmd.fargs or nil)
end, { nargs = "*", complete = plugin_names, desc = "Update plugins (review, then :write)" })

-- :PackList   what's installed, and at which version (nothing is downloaded)
vim.api.nvim_create_user_command("PackList", function()
    vim.pack.update(nil, { offline = true })
end, { desc = "List installed plugins" })

-- :PackClean   remove plugins that are no longer in lua/plugins.lua
vim.api.nvim_create_user_command("PackClean", function()
    local unused = vim.iter(vim.pack.get())
        :filter(function(p) return not p.active end)
        :map(function(p) return p.spec.name end)
        :totable()
    if #unused == 0 then
        vim.notify("No unused plugins")
        return
    end
    if vim.fn.confirm("Remove " .. table.concat(unused, ", ") .. "?", "&Yes\n&No", 2) == 1 then
        vim.pack.del(unused)
    end
end, { desc = "Remove plugins that aren't listed any more" })

-- ---- keys ----
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>f", ":find ", { desc = "Find a file" })
map("n", "<leader>b", ":buffer ", { desc = "Switch buffer" })
map("n", "<leader>/", ":silent grep! ", { desc = "Search the project" })
map("n", "-", "<cmd>Explore<cr>", { desc = "File explorer" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic under the cursor" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

-- windows
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- keep the selection while indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- completion menu
map("i", "<Tab>", function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>" end, { expr = true })
map("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end, { expr = true })

-- command line: ↑ ↓ keep walking history even while suggestions show
map("c", "<Up>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>" end, { expr = true })
map("c", "<Down>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>" end, { expr = true })

-- ---- small comforts ----
local group = vim.api.nvim_create_augroup("shinrai", { clear = true })
local autocmd = function(event, opts)
    opts.group = group
    vim.api.nvim_create_autocmd(event, opts)
end

-- suggestions in the command line as you type
autocmd("CmdlineChanged", { pattern = ":", callback = function() vim.fn.wildtrigger() end })
-- a fresh file list for every :find
autocmd("CmdlineEnter", { pattern = ":", callback = function() files = nil end })
-- the statusline follows mode and diagnostics right away
autocmd({ "ModeChanged", "DiagnosticChanged" }, { command = "redrawstatus" })
-- open search results in the quickfix list
autocmd("QuickFixCmdPost", { pattern = "grep", command = "cwindow" })
-- a brief flash on what you yank
autocmd("TextYankPost", { callback = function() vim.hl.on_yank({ timeout = 160 }) end })
-- reopen files where you left them
autocmd("BufReadPost", {
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
-- tree-sitter highlighting wherever a parser is installed
autocmd("FileType", { callback = function(args) pcall(vim.treesitter.start, args.buf) end })

-- ---- plugins (lua/plugins.lua, through Neovim's built-in vim.pack) ----
-- Last, so a plugin's keys (Space f, -, ...) take over from the built-in ones.
require("plugins")
