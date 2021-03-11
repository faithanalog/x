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

lunajson = require("lunajson")

function log(s)
    io.stderr:write(s) 
    io.stderr:write("\n")
end

-- parse field, return string and remainder
function parse_field(s)
    local field, remainder = nil, s
    local qstart, qend = s:find('^".-[^\\]"[,\n]')
    if qstart ~= nil then
        field = s:sub(2, qend - 2)
        remainder = s:sub(qend)
    else
        qstart, qend = s:find('^[^,\n]-[,\n]')
        if qstart ~= nil then
            field = s:sub(1, qend - 1)
            remainder = s:sub(qend)
        end
    end
    return field, remainder
end

-- parse a row to array
function parse_row(s)
    local row = {}
    local idx = 1
    local term = ","
    while term == "," do
        row[idx], s = parse_field(s)
        idx = idx + 1
        term = s:sub(1, 1)
        s = s:sub(2)
    end
    return row, s
end

function parse_file(s)
    -- remove carriage returns
    s = s:gsub("\r", "")
    -- append a newline if there isnt one because we use it to indicate end of row
    if s:sub(-1) ~= "\n" then
        s = s .. "\n"
    end
    local db = {}
    local idx = 1
    local header
    header, s = parse_row(s)
    while true do
        local row
        row, s = parse_row(s)
        if #row == 0 then
            return db, header, s
        end

        local row_tagged = {}
        for i, v in ipairs(row) do
            row_tagged[header[i]] = v
        end
        db[idx] = row_tagged
        idx = idx + 1
    end
end



local input = io.read("*all")

local db, header, s = parse_file(input)

local out = {
    keys = header,
    rows = db
}

io.stderr:write(s)

print(lunajson.encode(out))
