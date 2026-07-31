############################
# Login Session
############################
if status is-login
    bash ~/.config/sway/gsetting.sh

    # Environment
    set -Ux GTK_THEME Tokyonight-Night
    set -Ux PATH $HOME/.local/bin $PATH
    set -Ux PATH $HOME/.bun/bin $PATH
    set -Ux PATH $HOME/.npm-global/bin $PATH
    set -Ux MANPAGER "nvim +Man!"

end

############################
# Interactive Shell
############################
if status is-interactive

    # Tools
    starship init fish | source
    zoxide init fish | source

end

############################
# Greeting Shell
############################
function fish_greeting
    if test "$TERM" = foot
        fastfetch -c ~/.config/fastfetch/presets/simple.jsonc
    end
end

############################
# Fzf Config
############################
# Export
set -gx FZF_DEFAULT_OPTS "
  --highlight-line
  --info=inline-right
  --ansi
  --layout=reverse
  --border=none
  --color=bg+:#283457
  --color=bg:#16161e
  --color=border:#27a1b9
  --color=fg:#c0caf5
  --color=gutter:#16161e
  --color=header:#ff9e64
  --color=hl+:#2ac3de
  --color=hl:#2ac3de
  --color=info:#545c7e
  --color=marker:#ff007c
  --color=pointer:#ff007c
  --color=prompt:#2ac3de
  --color=query:#c0caf5:regular
  --color=scrollbar:#27a1b9
  --color=separator:#ff9e64
  --color=spinner:#ff007c
  "

# Source
fzf --fish | source


############################
# Alias
############################
alias sudo='sudo '
alias c='clear'
alias v='nvim'
alias vi='nvim .'
alias lg='lazygit'
alias tmx='tmux new-session -A -s main'
alias start='sudo systemctl start'
alias stop='sudo systemctl stop'
alias ff='fastfetch'
alias fishconfig='nvim ~/.config/fish/config.fish'

# Sway
alias getappid="swaymsg -t get_tree | jq '.. | select(.app_id?) | .app_id' | sort -u"
alias getapptitle="swaymsg -t get_tree | jq '.. | select(.name?) | .name' | sort -u"

# Paket
alias paccek='yay -Q | grep'
alias update='sudo pacman -Syu'

# Git
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

# Docker
alias cleandock='docker container prune -f && docker volume prune -f && docker network prune -f'

# System
alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias fixpacman='sudo rm /var/lib/pacman/db.lck'
alias hw='hwinfo --short'
alias mirror='sudo reflector --country Indonesia --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'
alias ls='eza -al --color=always --group-directories-first --icons'

# Journal
alias jctl='journalctl -p 3 -xb'
alias clrjctl='sudo journalctl --vacuum-time=1s'


# pnpm
set -gx PNPM_HOME "/home/gilang/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
