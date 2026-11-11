# shinrai · zsh
# Violet greys with the wallpaper's purple: the prompt, what you type,
# completion menus, ls and man pages.

export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim VISUAL=nvim

# ---- history ----
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY EXTENDED_HISTORY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP

# ---- ls / eza colors: folders purple, programs bright, everything else quiet ----
export LS_COLORS='di=1;35:ln=37:so=37:pi=37:ex=1;37:bd=37:cd=37:su=37:sg=37:tw=1;35:ow=1;35:or=31:mi=31'
# "reset" drops eza's own colors (pink images, yellow archives, ...)
export EZA_COLORS='reset:di=1;35:ex=1;37:ln=37:or=31:lp=90:ur=37:uw=37:ux=37:ue=37:gr=90:gw=90:gx=90:tr=90:tw=90:tx=90:su=90:sf=90:xa=90:sn=37:sb=90:df=37:ds=90:uu=90:un=37:gu=90:gn=37:lc=90:lm=90:da=90:in=90:bl=90:hd=4;37:xx=90:ga=32:gm=33:gd=31:gv=33:gt=33'

# ---- completion: a menu you move through with Tab / arrows ----
zmodload zsh/complist
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#5a5266}%d%f'
zstyle ':completion:*:warnings' format '%F{#5a5266}nothing to complete%f'
# list in the ls colors; the chosen entry inverted, like the island
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=7'

# ---- keys: emacs style ----
bindkey -e
# ↑ ↓ search history for what you've typed so far
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
# Ctrl + ← → by words, Ctrl + Backspace deletes one, Home / End / Delete
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
# Shift + Tab walks the completion menu backwards
bindkey -M menuselect '^[[Z' reverse-menu-complete

# ---- prompt ----
#   ~/dots main ›
# path in grey, git branch in dim purple, the arrow purple (grey after a failed command)
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{#8a6db0}%b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{#8a6db0}%b · %a%f'
autoload -Uz add-zsh-hook
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{#77707f}%~%f${vcs_info_msg_0_} %(?.%F{#b287e3}.%F{#5a5266})›%f '

# ---- plugins (from the Arch repos) ----
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] &&
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] &&
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# suggestions from history, barely there
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#3d3447'

# what you type: commands white, keywords purple, arguments softer, mistakes soft red
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#d3cddb'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e88ea0'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#b287e3,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[function]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[command]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#f6f3fa,underline'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#f6f3fa'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#77707f'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#d3cddb,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#d3cddb,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#d3cddb,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#77707f,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#a59db0'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#e6e1ec'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#e6e1ec'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#77707f'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#77707f'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#d3cddb'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#77707f'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5a5266'

# ---- man pages: read in Neovim, in the same colors ----
command -v nvim >/dev/null && export MANPAGER='nvim +Man!'

# ---- aliases ----
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -l --group-directories-first --icons=auto --git'
    alias la='eza -la --group-directories-first --icons=auto --git'
    alias tree='eza --tree --icons=auto'
fi
alias grep='grep --color=auto'
alias vim='nvim'
alias vis='cava'
