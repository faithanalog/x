# dns-adblock

There are a few helper scripts for generating dns-level adblocking configurations, based on list generation code from [pi-hole](https://pi-hole.net). They sanitize the output, removing all comments and other stuff that configuration parsers might not like. They also ensure that the upstream lists can't inject any evil DNS redirects by inserting a mapping to 0.0.0.0 during the processing steps, instead of relying on upstream to do it.

[download-lists-and-generate-etchosts-dnsmasq.sh](download-lists-and-generate-etchosts-dnsmasq.sh) generates a file in the current working directory named `adblock.list`. This file is compatible with `/etc/hosts` and [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) config files - just append it to either of them.

[download-lists-and-generate-zonefile.sh](download-lists-and-generate-zonefile.sh) does the same thing, but generates a [zone file](https://en.wikipedia.org/wiki/Zone_file) named `adblock.zone` instead.

