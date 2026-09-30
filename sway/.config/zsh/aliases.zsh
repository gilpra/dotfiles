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
