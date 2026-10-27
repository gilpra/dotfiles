# ============================
# Functions
# ============================

# Fedora package manager helper: pkg install <name>, pkg remove <name>, etc.
pkg() {
    if (( $# == 0 )); then
        sudo dnf upgrade --refresh
    else
        sudo dnf "$@"
    fi
}

# Remove dependencies that are no longer needed.
cleanup() {
    sudo dnf autoremove
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
