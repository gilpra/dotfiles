function cleanup --description "Remove orphaned packages"
    set orphaned (pacman -Qtdq)
    if test -n "$orphaned"
        sudo pacman -Rns $orphaned
    else
        echo "There are no packages to clean."
    end
end
