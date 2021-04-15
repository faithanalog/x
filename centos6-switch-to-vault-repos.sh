#!/bin/bash
# this changes all *.centos.org repos to vault.centos.org so yum will work again.
# consider migrating to centos7 after you do this because centos6 is EOL
sed -i 's|^[# ]*baseurl=http://[^.]\+\.centos\.org|baseurl=http://vault.centos.org|g; s|^ *mirrorlist=http://mirrorlist\.centos\.org.*$||g' /etc/yum.repos.d/*.repo
