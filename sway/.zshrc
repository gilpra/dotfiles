# ============================
# Zsh Options
# ============================

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit
compinit

# Better directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Globbing
setopt EXTENDED_GLOB

# ============================
# Completion Style
# ============================

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
    'm:{a-z}={A-Z}' \
    'r:|[._-]=* r:|=*'

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================
# Key Bindings
# ============================

bindkey -e

# Fish-like history search
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ============================
# Autosuggestion
# ============================

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ============================
# Syntax Highlighting
# ============================

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================
# fzf
# ============================

export FZF_DEFAULT_OPTS='
  --highlight-line
  --info=inline-right
  --ansi
  --layout=reverse
  --border=none
  --color=bg+:#202020
  --color=bg:#181818
  --color=border:#8FD19E
  --color=fg:#E8E8E8
  --color=gutter:#181818
  --color=header:#B8B8B8
  --color=hl+:#B7E4C7
  --color=hl:#8FD19E
  --color=info:#8A8A8A
  --color=marker:#8FD19E
  --color=pointer:#8FD19E
  --color=prompt:#8FD19E
  --color=query:#E8E8E8:regular
  --color=scrollbar:#8FD19E
  --color=separator:#B8B8B8
  --color=spinner:#8FD19E
'

if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# ============================
# zoxide
# ============================

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

# ============================
# Starship
# ============================

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# ============================
# Greeting
# ============================

if [[ "$TERM" == "foot" && -z "$YAZI_SHELL" ]]; then
    fastfetch -c "$HOME/.config/fastfetch/presets/simple.jsonc"
fi

# ============================
# Alias
# ============================

alias sudo='sudo '

alias c='clear'
alias v='nvim'
alias vi='nvim .'
alias lg='lazygit'
alias tmx='tmux new-session -A -s main'

alias start='sudo systemctl start'
alias stop='sudo systemctl stop'

alias ff='fastfetch'

# ============================
# Sway
# ============================

alias getappid="swaymsg -t get_tree | jq '.. | select(.app_id?) | .app_id' | sort -u"
alias getapptitle="swaymsg -t get_tree | jq '.. | select(.name?) | .name' | sort -u"

# ============================
# Git
# ============================

alias gi='git init'
alias gs='git status'
alias ga='git add .'
alias gcm='git commit -m'
alias gp='git push'
alias gc='git clone'
alias gf='git fetch'
alias grh='git reset --hard'
alias grr='git remote remove'
alias gl='git log'
alias gls="git log --pretty=format:'%h | %ad | %cd | %s' --date=format:'%Y-%m-%d %H:%M:%S'"
alias gr='git rebase'

# ============================
# System
# ============================

alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias fixpacman='sudo rm /var/lib/pacman/db.lck'
alias mirror='sudo reflector --country Indonesia --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'
alias ls='eza -al --color=always --group-directories-first --icons=always'

# ============================
# Functions
# ============================

yay() {
    if [[ $# -eq 0 ]]; then
        sudo pacman -Syu
    else
        sudo pacman "$@"
    fi
}

cleanup() {
    local orphaned

    orphaned=("${(@f)$(pacman -Qtdq 2>/dev/null)}")

    if (( ${#orphaned[@]} > 0 )); then
        sudo pacman -Rns -- "${orphaned[@]}"
    else
        echo "There are no packages to clean."
    fi
}

y() {
    local tmp cwd

    tmp="$(mktemp -t 'yazi-cwd.XXXXXX')" || return

    yazi "$@" --cwd-file="$tmp"

    if [[ -r "$tmp" ]]; then
        IFS= read -r cwd < "$tmp"

        if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
            builtin cd -- "$cwd"
        fi
    fi

    rm -f -- "$tmp"
}

if [[ "$YAZI_SHELL" == 1 ]]; then
    unset YAZI_SHELL
    y
fi
