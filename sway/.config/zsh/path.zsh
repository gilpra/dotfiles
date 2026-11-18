# ============================
# PATH
# ============================

typeset -U path PATH
path=("$HOME"/Applications/*/bin(N/) $path)

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
