-- shinrai · plugins, through Neovim's own plugin manager (vim.pack)
--
-- Nothing to install: vim.pack is built into Neovim 0.12. It clones plugins
-- with git into ~/.local/share/nvim/site/pack/core/opt and pins the exact
-- versions in nvim-pack-lock.json, next to init.lua.
--
--   add      put the plugin's address in the list below, then :restart
--            (the first time, Neovim asks before downloading)
--   update   :PackUpdate   review what changed, :write to apply, :quit to skip
--   look     :PackList     what's installed, and at which version
--   remove   delete it from the list, :restart, then :PackClean
--
-- Each plugin is set up inside a pcall: if one isn't there (no network on
-- the first start), Neovim still starts, with the built-in picker and explorer.

local gh = function(repo) return "https://github.com/" .. repo end
local release = vim.version.range("*")   -- follow tagged releases, not every commit

vim.pack.add({
    { src = gh("lewis6991/gitsigns.nvim"), version = release },   -- git changes in the margin
    { src = gh("stevearc/oil.nvim"), version = release },          -- files as an editable buffer
    { src = gh("nvim-mini/mini.pick"), version = release },        -- fuzzy picker with live search
})

local map = vim.keymap.set

-- ---- gitsigns: thin bars where lines were added or changed, a mark where removed ----
--   ]h [h  next / previous change · Space gp preview · gs stage · gr undo · gb blame on/off
local ok_git, gitsigns = pcall(require, "gitsigns")
if ok_git then
    local function signs()
        return {
            add = { text = "▎" },
            change = { text = "▎" },
            changedelete = { text = "▎" },
            delete = { text = "▁" },
            topdelete = { text = "▔" },
            untracked = { text = "┆" },
        }
    end

    gitsigns.setup({
        signs = signs(),
        signs_staged = signs(),
        current_line_blame_formatter = "<author>, <author_time:%R> · <summary>",
        on_attach = function(buf)
            local function m(lhs, rhs, desc) map("n", lhs, rhs, { buffer = buf, desc = desc }) end
            m("]h", function() gitsigns.nav_hunk("next") end, "Next git change")
            m("[h", function() gitsigns.nav_hunk("prev") end, "Previous git change")
            m("<leader>gp", gitsigns.preview_hunk, "Preview this change")
            m("<leader>gs", gitsigns.stage_hunk, "Stage this change")
            m("<leader>gr", gitsigns.reset_hunk, "Undo this change")
            m("<leader>gb", gitsigns.toggle_current_line_blame, "Blame on / off")
        end,
    })
end

-- ---- oil: the folder as a buffer; rename, move or delete by editing, then :w ----
--   -  open (and go up)   Enter  open   g.  hidden files   _  back to the project
local ok_oil, oil = pcall(require, "oil")
if ok_oil then
    oil.setup({
        default_file_explorer = true,     -- instead of netrw
        columns = {},                     -- just names (no icons, no colors)
        skip_confirm_for_simple_edits = true,
        delete_to_trash = true,           -- deleted files go to the trash
        view_options = { show_hidden = false },
    })
    map("n", "-", "<cmd>Oil<cr>", { desc = "File explorer" })
end

-- ---- mini.pick: a floating picker in the middle, like the island's launcher ----
--   Space f files · Space / search the project live · Space b buffers
--   Space h help · Space ' reopen the last picker
--   in the picker: type to filter, Enter open, Ctrl-v / Ctrl-s split, Tab preview, Esc close
local ok_pick, pick = pcall(require, "mini.pick")
if ok_pick then
    pick.setup({
        window = {
            prompt_prefix = "› ",
            config = function()
                local width = math.min(100, math.floor(vim.o.columns * 0.6))
                local height = math.floor(vim.o.lines * 0.45)
                return {
                    anchor = "NW",
                    row = math.floor(vim.o.lines * 0.15),
                    col = math.floor((vim.o.columns - width) / 2),
                    width = width,
                    height = height,
                    border = "rounded",
                }
            end,
        },
    })
    map("n", "<leader>f", pick.builtin.files, { desc = "Find a file" })
    map("n", "<leader>/", pick.builtin.grep_live, { desc = "Search the project" })
    map("n", "<leader>b", pick.builtin.buffers, { desc = "Switch buffer" })
    map("n", "<leader>h", pick.builtin.help, { desc = "Search help" })
    map("n", "<leader>'", pick.builtin.resume, { desc = "Reopen the last picker" })
end
