function y --description "Yazi with cwd integration" --wraps yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    set cwd (cat -- "$tmp")
    if test -n "$cwd" -a "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
