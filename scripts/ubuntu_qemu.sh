#!/bin/bash

# Update grub to fix the QEMU boot stall looking for 'root' disk
sudo update-grub
sudo apt install --assume-yes qemu-agent

exit
