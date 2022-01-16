
function chain(name, default, rules)
    return { name = name, default = default, rules = rules }
end

function accept(rule)
    rule.target = 'ACCEPT'
    return rule
end

function drop(rule)
    rule.target = 'DROP'
    return rule
end

local function gen_rule(chain, rule)
    local out = '-A ' .. chain
    if rule.conntrack ~= nil then
        out = out .. ' -m conntrack'
        if rule.conntrack == 'the usual' then
            out = out .. ' --ctstate ESTABLISHED,RELATED'
        else
            return 'ERR: cant handle conntrack set to ' .. rule.conntrack
        end
    end
    if rule.source ~= nil then
        out = out .. ' -s ' .. rule.source
    end
    if rule.tcp ~= nil then
        if rule.udp ~= nil then
            return 'ERR: cannot allow tcp and udp port in the same rule'
        end
        out = out .. ' -p tcp --dport ' .. rule.tcp
    end
    if rule.udp ~= nil then
        out = out .. ' -p udp --dport ' .. rule.udp
    end
    if rule.icmp ~= nil then
        return 'ERR: icmp not implemented'
    end
    if rule.iface ~= nil then
        out = out .. ' -i ' .. rule.iface
    end
    out = out .. ' -j ' .. rule.target
    return out
end

local function gen_chain(chain, iptables_save)
    local name = chain.name
    local out
    if iptables_save then
        out = ':' .. name .. ' ' .. chain.default .. ' [0:0]'
    else
        out = '-P ' .. name .. ' ' .. chain.default
    end
    for _,rule in ipairs(chain.rules) do
        out = out .. '\n' .. gen_rule(name, rule)
    end
    return out
end


ipv6 = arg[1] == 'ipv6'

require('./rules')

if iptables_save then
    print ('*filter')
else
    print('-F')
end
print()
print(gen_chain(input, iptables_save))
print()
print(gen_chain(forward, iptables_save))
print()
print(gen_chain(output, iptables_save))
if iptables_save then
    print ('COMMIT')
end

