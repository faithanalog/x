#!/bin/sh

set -ev

PREFIX=/usr/local

if ! (which bundle 1>/dev/null 2>/dev/null); then
    echo "Err: install ruby and bundler"
    exit 1
fi

install --mode 644 -D -t "$PREFIX/lib/systemd/system" artemis-upload-service.service 
install --mode 644 -D -t "$PREFIX/share/artemis-upload-service" Gemfile
install --mode 755 -D -t "$PREFIX/share/artemis-upload-service" artemis-upload-service.rb
install --mode 755 -d /var/artemis-upload-service/public/files
install --mode 755 -t "$PREFIX/bin" art-up

if ! [ -f /etc/artemis-upload-service.conf ]; then
    install --mode 600 -C -t "/etc" artemis-upload-service.conf
fi

cd "$PREFIX/share/artemis-upload-service"
rm Gemfile.lock || true
bundle install --system
