#!/bin/bash

# NAT it when the destination IP is 10.15.20.25 (our hello world server)
iptables -t nat -A POSTROUTING -d 10.15.20.25/32 -o eth0 -j MASQUERADE
# NAT it when the destination IP is 10.15.20.1 (use eth0 to NAT the incoming packets)
iptables -t nat -A POSTROUTING -d 10.15.20.1/32 -o eth0 -j MASQUERADE
