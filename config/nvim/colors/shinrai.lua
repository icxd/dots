-- shinrai · a monochrome colorscheme for Neovim
--
-- The same greys as kitty and the desktop. Syntax is told apart by brightness
-- and weight, not hue: keywords bold white, functions bright, strings a softer
-- grey, comments dim and italic. Muted tints appear only where they carry
-- meaning: errors, warnings, git changes.

vim.cmd.highlight("clear")
if vim.g.syntax_on then vim.cmd.syntax("reset") end
vim.o.background = "dark"
vim.g.colors_name = "shinrai"

local c = {
    bg      = "#000000",   -- same as kitty
    bg1     = "#0b0b0c",   -- cursor line
    bg3     = "#1f1f22",   -- selection, popup selection
    line    = "#27272a",   -- borders, separators
    faint   = "#3f3f46",   -- line numbers, invisible characters
    dim     = "#52525b",   -- comments
    mute    = "#71717a",   -- punctuation, operators
    soft    = "#a1a1aa",   -- strings
    mid     = "#d4d4d8",   -- types, constants
    fg      = "#e4e4e7",   -- text
    bright  = "#fafafa",   -- keywords, functions
    white   = "#ffffff",
    -- muted tints, only where meaning needs them
    red     = "#d4a5a5",
    yellow  = "#d6c9a5",
    green   = "#a8c4a8",
    blue    = "#a5b4d4",
    red_bg    = "#1a0f0f",
    yellow_bg = "#1a170f",
    green_bg  = "#0f1a10",
    blue_bg   = "#0f121a",
}

local groups = {
    -- ---- editor ----
    Normal       = { fg = c.fg, bg = c.bg },
    NormalNC     = { link = "Normal" },
    NormalFloat  = { fg = c.fg, bg = c.bg },
    FloatBorder  = { fg = c.faint, bg = c.bg },
    FloatTitle   = { fg = c.bright, bg = c.bg, bold = true },
    FloatFooter  = { fg = c.mute, bg = c.bg },
    Cursor       = { fg = c.bg, bg = c.white },
    CursorLine   = { bg = c.bg1 },
    CursorColumn = { bg = c.bg1 },
    ColorColumn  = { bg = c.bg1 },
    CursorLineNr = { fg = c.bright, bold = true },
    LineNr       = { fg = c.faint },
    LineNrAbove  = { link = "LineNr" },
    LineNrBelow  = { link = "LineNr" },
    SignColumn   = { bg = c.bg },
    FoldColumn   = { fg = c.faint },
    Folded       = { fg = c.mute, bg = c.bg1 },
    Visual       = { bg = c.bg3 },
    VisualNOS    = { bg = c.bg3 },
    Search       = { fg = c.bg, bg = c.soft },
    CurSearch    = { fg = c.bg, bg = c.white, bold = true },
    IncSearch    = { link = "CurSearch" },
    Substitute   = { fg = c.bg, bg = c.mid },
    MatchParen   = { fg = c.white, bold = true, underline = true },
    NonText      = { fg = c.faint },
    Whitespace   = { fg = c.line },
    SpecialKey   = { fg = c.faint },
    EndOfBuffer  = { fg = c.bg },
    Conceal      = { fg = c.mute },
    Directory    = { fg = c.bright, bold = true },
    Title        = { fg = c.bright, bold = true },
    WinSeparator = { fg = c.line },
    VertSplit    = { link = "WinSeparator" },
    QuickFixLine = { bg = c.bg3 },

    -- statusline / tabline (the statusline itself draws its own pieces)
    StatusLine   = { fg = c.mid, bg = c.bg },
    StatusLineNC = { fg = c.dim, bg = c.bg },
    TabLine      = { fg = c.mute, bg = c.bg },
    TabLineFill  = { bg = c.bg },
    TabLineSel   = { fg = c.bg, bg = c.fg, bold = true },
    WinBar       = { fg = c.mute, bg = c.bg },
    WinBarNC     = { fg = c.faint, bg = c.bg },

    -- popup menu: the chosen item inverted, like the island
    Pmenu        = { fg = c.mid, bg = c.bg },
    PmenuSel     = { fg = c.bg, bg = c.fg, bold = true },
    PmenuKind    = { fg = c.mute, bg = c.bg },
    PmenuKindSel = { fg = c.bg, bg = c.fg },
    PmenuExtra   = { fg = c.dim, bg = c.bg },
    PmenuExtraSel = { fg = c.bg1, bg = c.fg },
    PmenuMatch   = { fg = c.white, bold = true },
    PmenuMatchSel = { fg = c.bg, bg = c.fg, bold = true, underline = true },
    PmenuSbar    = { bg = c.bg },
    PmenuThumb   = { bg = c.faint },
    PmenuBorder  = { fg = c.faint, bg = c.bg },
    WildMenu     = { link = "PmenuSel" },
    ComplMatchIns = { fg = c.dim },

    -- messages
    ModeMsg      = { fg = c.mid },
    MsgArea      = { fg = c.mid },
    MoreMsg      = { fg = c.soft },
    Question     = { fg = c.soft },
    ErrorMsg     = { fg = c.red },
    WarningMsg   = { fg = c.yellow },

    -- spelling
    SpellBad     = { undercurl = true, sp = c.red },
    SpellCap     = { undercurl = true, sp = c.yellow },
    SpellLocal   = { undercurl = true, sp = c.blue },
    SpellRare    = { undercurl = true, sp = c.mute },

    -- diff / git
    DiffAdd      = { bg = c.green_bg },
    DiffChange   = { bg = c.blue_bg },
    DiffDelete   = { fg = c.red, bg = c.red_bg },
    DiffText     = { bg = "#18202e" },
    Added        = { fg = c.green },
    Changed      = { fg = c.blue },
    Removed      = { fg = c.red },

    -- ---- syntax ----
    Comment      = { fg = c.dim, italic = true },
    Constant     = { fg = c.mid },
    String       = { fg = c.soft },
    Character    = { fg = c.soft },
    Number       = { fg = c.mid },
    Boolean      = { fg = c.mid, bold = true },
    Float        = { link = "Number" },
    Identifier   = { fg = c.fg },
    Function     = { fg = c.bright },
    Statement    = { fg = c.bright, bold = true },
    Conditional  = { link = "Statement" },
    Repeat       = { link = "Statement" },
    Label        = { link = "Statement" },
    Keyword      = { link = "Statement" },
    Exception    = { link = "Statement" },
    Operator     = { fg = c.mute },
    PreProc      = { fg = c.mid },
    Include      = { fg = c.bright, bold = true },
    Define       = { link = "PreProc" },
    Macro        = { link = "PreProc" },
    PreCondit    = { link = "PreProc" },
    Type         = { fg = c.mid, italic = true },
    StorageClass = { link = "Statement" },
    Structure    = { link = "Type" },
    Typedef      = { link = "Type" },
    Special      = { fg = c.mid },
    SpecialChar  = { fg = c.fg },
    Tag          = { fg = c.bright },
    Delimiter    = { fg = c.mute },
    SpecialComment = { fg = c.mute, italic = true },
    Debug        = { fg = c.mid },
    Underlined   = { underline = true },
    Ignore       = { fg = c.faint },
    Error        = { fg = c.red },
    Todo         = { fg = c.bg, bg = c.soft, bold = true },

    -- ---- treesitter ----
    ["@variable"]            = { fg = c.fg },
    ["@variable.builtin"]    = { fg = c.mid, italic = true },
    ["@variable.parameter"]  = { fg = c.fg, italic = true },
    ["@variable.member"]     = { fg = c.mid },
    ["@constant"]            = { link = "Constant" },
    ["@constant.builtin"]    = { fg = c.mid, bold = true },
    ["@module"]              = { fg = c.mid },
    ["@label"]               = { link = "Label" },
    ["@string"]              = { link = "String" },
    ["@string.escape"]       = { fg = c.fg },
    ["@string.special"]      = { fg = c.fg },
    ["@string.regexp"]       = { fg = c.fg },
    ["@character"]           = { link = "Character" },
    ["@number"]              = { link = "Number" },
    ["@boolean"]             = { link = "Boolean" },
    ["@type"]                = { link = "Type" },
    ["@type.builtin"]        = { fg = c.mid, italic = true },
    ["@attribute"]           = { fg = c.mute },
    ["@property"]            = { fg = c.mid },
    ["@function"]            = { link = "Function" },
    ["@function.builtin"]    = { fg = c.bright, italic = true },
    ["@function.call"]       = { fg = c.fg },
    ["@function.method.call"] = { fg = c.fg },
    ["@constructor"]         = { fg = c.bright },
    ["@operator"]            = { link = "Operator" },
    ["@keyword"]             = { link = "Keyword" },
    ["@keyword.return"]      = { fg = c.white, bold = true },
    ["@keyword.import"]      = { link = "Include" },
    ["@punctuation"]         = { fg = c.mute },
    ["@punctuation.delimiter"] = { fg = c.mute },
    ["@punctuation.bracket"] = { fg = c.mute },
    ["@punctuation.special"] = { fg = c.mute },
    ["@comment"]             = { link = "Comment" },
    ["@comment.todo"]        = { link = "Todo" },
    ["@comment.note"]        = { fg = c.bg, bg = c.blue, bold = true },
    ["@comment.warning"]     = { fg = c.bg, bg = c.yellow, bold = true },
    ["@comment.error"]       = { fg = c.bg, bg = c.red, bold = true },
    ["@tag"]                 = { link = "Tag" },
    ["@tag.attribute"]       = { fg = c.mid, italic = true },
    ["@tag.delimiter"]       = { fg = c.mute },
    ["@markup.heading"]      = { fg = c.white, bold = true },
    ["@markup.strong"]       = { bold = true },
    ["@markup.italic"]       = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"]    = { underline = true },
    ["@markup.link"]         = { fg = c.mid },
    ["@markup.link.url"]     = { fg = c.soft, underline = true },
    ["@markup.raw"]          = { fg = c.soft },
    ["@markup.list"]         = { fg = c.mute },
    ["@markup.quote"]        = { fg = c.soft, italic = true },
    ["@diff.plus"]           = { link = "Added" },
    ["@diff.minus"]          = { link = "Removed" },
    ["@diff.delta"]          = { link = "Changed" },

    -- LSP semantic tokens follow the treesitter groups
    ["@lsp.type.namespace"]  = { link = "@module" },
    ["@lsp.type.type"]       = { link = "@type" },
    ["@lsp.type.class"]      = { link = "@type" },
    ["@lsp.type.enum"]       = { link = "@type" },
    ["@lsp.type.interface"]  = { link = "@type" },
    ["@lsp.type.struct"]     = { link = "@type" },
    ["@lsp.type.parameter"]  = { link = "@variable.parameter" },
    ["@lsp.type.variable"]   = { link = "@variable" },
    ["@lsp.type.property"]   = { link = "@property" },
    ["@lsp.type.enumMember"] = { link = "@constant" },
    ["@lsp.type.function"]   = { link = "@function" },
    ["@lsp.type.method"]     = { link = "@function" },
    ["@lsp.type.macro"]      = { link = "Macro" },
    ["@lsp.type.decorator"]  = { link = "@attribute" },
    ["@lsp.mod.deprecated"]  = { strikethrough = true },

    -- ---- diagnostics & LSP ----
    DiagnosticError = { fg = c.red },
    DiagnosticWarn  = { fg = c.yellow },
    DiagnosticInfo  = { fg = c.blue },
    DiagnosticHint  = { fg = c.mute },
    DiagnosticOk    = { fg = c.green },
    DiagnosticUnderlineError = { undercurl = true, sp = c.red },
    DiagnosticUnderlineWarn  = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo  = { undercurl = true, sp = c.blue },
    DiagnosticUnderlineHint  = { undercurl = true, sp = c.mute },
    DiagnosticVirtualTextError = { fg = c.red, bg = c.red_bg },
    DiagnosticVirtualTextWarn  = { fg = c.yellow, bg = c.yellow_bg },
    DiagnosticVirtualTextInfo  = { fg = c.blue, bg = c.blue_bg },
    DiagnosticVirtualTextHint  = { fg = c.mute, bg = c.bg1 },
    DiagnosticUnnecessary = { fg = c.dim },
    DiagnosticDeprecated  = { strikethrough = true },
    LspReferenceText  = { bg = c.bg3 },
    LspReferenceRead  = { bg = c.bg3 },
    LspReferenceWrite = { bg = c.bg3, underline = true },
    LspInlayHint      = { fg = c.dim, italic = true },
    LspSignatureActiveParameter = { fg = c.white, bold = true, underline = true },
    LspCodeLens       = { fg = c.dim },

    -- ---- netrw (the file explorer) ----
    netrwDir       = { link = "Directory" },
    netrwClassify  = { fg = c.mute },
    netrwExe       = { fg = c.bright },
    netrwSymLink   = { fg = c.soft, italic = true },
    netrwTreeBar   = { fg = c.line },
    netrwComment   = { link = "Comment" },
    netrwList      = { fg = c.mid },
    netrwHelpCmd   = { fg = c.mid },
    netrwVersion   = { fg = c.dim },
    netrwPlain     = { fg = c.fg },

    -- ---- plugins (lua/plugins.lua) ----
    -- gitsigns: the bars use Added / Changed / Removed; staged ones are dimmer
    GitSignsStagedAdd          = { fg = "#5c705c" },
    GitSignsStagedChange       = { fg = "#5c6680" },
    GitSignsStagedDelete       = { fg = "#806060" },
    GitSignsStagedChangedelete = { link = "GitSignsStagedChange" },
    GitSignsStagedTopdelete    = { link = "GitSignsStagedDelete" },
    GitSignsCurrentLineBlame   = { fg = c.dim, italic = true },

    -- oil: folders bright, hidden things dim, pending edits in the diff tints
    OilDir          = { link = "Directory" },
    OilDirHidden    = { fg = c.mute, bold = true },
    OilDirIcon      = { fg = c.mute },
    OilFile         = { fg = c.fg },
    OilFileHidden   = { fg = c.dim },
    OilHidden       = { fg = c.dim },
    OilLink         = { fg = c.soft, italic = true },
    OilLinkHidden   = { fg = c.dim, italic = true },
    OilLinkTarget   = { fg = c.dim },
    OilOrphanLink   = { fg = c.red, italic = true },
    OilOrphanLinkTarget = { fg = c.red },
    OilSocket       = { fg = c.mid },
    OilCreate       = { link = "Added" },
    OilDelete       = { link = "Removed" },
    OilMove         = { link = "Changed" },
    OilCopy         = { link = "Changed" },
    OilChange       = { link = "Changed" },
    OilRestore      = { link = "Added" },
    OilPurge        = { link = "Removed" },
    OilTrash        = { link = "Removed" },
    OilTrashSourcePath = { fg = c.dim },

    -- mini.pick: a dark panel, the current line inverted like the island
    MiniPickNormal        = { fg = c.mid, bg = c.bg },
    MiniPickBorder        = { fg = c.faint, bg = c.bg },
    MiniPickBorderBusy    = { fg = c.mute, bg = c.bg },
    MiniPickBorderText    = { fg = c.mute, bg = c.bg },
    MiniPickPrompt        = { fg = c.bright, bg = c.bg },
    MiniPickPromptPrefix  = { fg = c.mute, bg = c.bg },
    MiniPickPromptCaret   = { fg = c.white, bg = c.bg },
    MiniPickMatchCurrent  = { fg = c.bg, bg = c.fg, bold = true },
    MiniPickMatchMarked   = { fg = c.white, bg = c.bg3 },
    MiniPickMatchRanges   = { fg = c.white, bold = true },
    MiniPickHeader        = { fg = c.bright, bold = true },
    MiniPickIconDirectory = { fg = c.mute },
    MiniPickIconFile      = { fg = c.dim },
    MiniPickPreviewLine   = { bg = c.bg3 },
    MiniPickPreviewRegion = { bg = c.bg3 },

    -- ---- the statusline's own pieces (init.lua) ----
    ShinraiMode     = { fg = c.bg, bg = c.fg, bold = true },
    ShinraiModeEdge = { fg = c.fg, bg = c.bg },
    ShinraiFile     = { fg = c.fg, bg = c.bg, bold = true },
    ShinraiDim      = { fg = c.dim, bg = c.bg },
    ShinraiSoft     = { fg = c.mute, bg = c.bg },
    ShinraiError    = { fg = c.red, bg = c.bg },
    ShinraiWarn     = { fg = c.yellow, bg = c.bg },
}

for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
end

-- the terminal's 16 colors inside :terminal, same as kitty
local term = { "#18181b", c.red, c.green, c.yellow, c.blue, "#c4a8d4", "#a5cccc", c.mid,
               "#52525b", "#e5bcbc", "#bed6be", "#e6dbbd", "#bcc8e5", "#d6bee5", "#bddede", c.bright }
for i, color in ipairs(term) do
    vim.g["terminal_color_" .. (i - 1)] = color
end
