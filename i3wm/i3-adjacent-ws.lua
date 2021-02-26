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
-- changes workspace to workspace-1 or workspace+1. this exists because i3's
-- builtin relative workspace switcher will only cycle through workspaces with
-- at least one window. if ws < min_ws, ws = max_ws. if ws > max_ws, ws = min_ws
--
-- depends: luarocks install lunajson subproc
-- usage: i3-adjacent-ws.lua (left|prev|right|next) [min_ws=1] [max_ws=10]

lunajson = require 'lunajson'
subproc = require 'subproc'

direction = arg[1]
min_ws = tonumber(arg[2] or 1)
max_ws = tonumber(arg[3] or 10)


workspaces = lunajson.decode(subproc('i3-msg', '-t', 'get_workspaces'), nil)

for _, ws in pairs(workspaces) do
    if ws.focused then
        focused_ws = ws.num
    end
end

if direction == 'left' or direction == 'prev' then
    target = focused_ws - 1
    if target < min_ws then
        target = max_ws
    end
elseif direction == 'right' or direction == 'next' then
    target = focused_ws + 1
    if target > max_ws then
        target = min_ws
    end
else 
    print('error: invalid direction ' .. tostring(direction))
    os.exit(1)
end

subproc('i3-msg', 'workspace', 'number', target)
