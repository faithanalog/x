#!/bin/sh

rm Gemfile.lock
bundle install
./plt-rotate.rb colormap-loop.png drugblur.png frames/ 0 509
./animate.sh
