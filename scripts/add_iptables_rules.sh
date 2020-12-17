#!/bin/bash

# Note: 10.10.10.0/24 should be the same as rightsourceip in ipsec.conf
# `man iptables-extensions`
# https://ipset.netfilter.org/iptables-extensions.man.html
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT

# Perform source NAT on 10.10.10.0/24 (use eth0's IP)
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
