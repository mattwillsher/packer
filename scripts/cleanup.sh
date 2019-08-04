#!/bin/bash

# Clean up the system after build

set -euo pipefail

sudo apt-get -y autoremove
sudo apt-get -y clean
sudo rm -rf /tmp/*
cat /dev/null > ~/.bash_history
history -c

sudo cloud-init clean

exit
