#!/bin/bash
mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki

ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/ca-key.pem
ipsec pki --self --ca --lifetime 3650 --in ~/pki/private/ca-key.pem \
    --type rsa --dn "CN=BravoAI IPSec" --outform pem > ~/pki/cacerts/ca-cert.pem
