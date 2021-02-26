Adapted from http://lua-users.org/lists/lua-l/2015-01/msg00633.html

This will search $PATH for lua, lua*, and luajit*, executing the current file with first one it finds

```lua
#!/bin/sh
_=[[
IFS=":"
for dir in $PATH; do
    for lua in "$dir"/lua "$dir"/lua5* "$dir"/luajit*; do
        if [ -x "$lua" ]; then
            exec "$lua" "$0" "$@"
        fi
    done
done
printf '%s: no lua found\n' "$0" >&2
exit 1
]]
print("lua code here!")
```

This shebang works by running the script with /bin/sh.

in /bin/sh:
- `_=[[` sets the `_` variable to `"[["
- the for-loop runs
- if no lua is found, `sh` dies with `exit 1`
- if a lua is found, `exec` replaces the `sh` process with a `lua` process, providing the current file as the first argument.

in lua:
- `_=[[` starts defining `_` and opens a multi-line comment
- the sh code is ignored because it's in the comment
- `]]` closes the comment, and `_` is defined to a 0-length string
- the lua file runs as normal
