fza() {
    f="$(ag "$1" | fzf)"
    if [ -n "$f" ]; then
        ag -l "$1" | awk -v 'f='"$f" '
            index(f, $0 ":") == 1 {
                print $0
                exit
            }
        '
    fi
}
