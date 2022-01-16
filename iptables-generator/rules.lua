-- customize rules here

input = chain('INPUT', 'DROP', {
    accept{conntrack = 'the usual'},
    accept{tcp = 22},
    accept{iface = 'lo'}
})

forward = chain('FORWARD', 'DROP', {
})

output = chain('OUTPUT', 'ACCEPT', {
})

iptables_save = true
