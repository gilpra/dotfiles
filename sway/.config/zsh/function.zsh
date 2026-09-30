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
