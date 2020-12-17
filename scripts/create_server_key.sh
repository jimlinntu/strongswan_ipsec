#!/bin/bash
ipsec pki --gen --type rsa --size 4096 --outform pem > ~/pki/private/server-key.pem
ipsec pki --pub --in ~/pki/private/server-key.pem --type rsa \
    | ipsec pki --issue --lifetime 1825 \
        --cacert ~/pki/cacerts/ca-cert.pem \
        --cakey ~/pki/private/ca-key.pem \
        --dn "CN=125.227.38.80" --san "125.227.38.80" \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  ~/pki/certs/server-cert.pem

