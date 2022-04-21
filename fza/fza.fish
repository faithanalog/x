function fza
    set f (ag $argv | fzf)
    if [ -n $f ]
        ag -l $argv | awk -v 'f='$f '
            index(f, $0 ":") == 1 {
                print $0
                exit
            }
        '
    end
end

