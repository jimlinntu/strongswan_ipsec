# IPSec Setup via strongSwan

## Environment
* `docker info`
```
Client:
 Version:           18.09.8
 API version:       1.39
 Go version:        go1.10.8
 Git commit:        0dd43dd87f
 Built:             Wed Jul 17 17:41:19 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.8
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.8
  Git commit:       0dd43dd
  Built:            Wed Jul 17 17:07:25 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```
* `docker-compose version`
```
docker-compose version 1.24.0, build 0aa59064
docker-py version: 3.7.2
CPython version: 3.6.8
OpenSSL version: OpenSSL 1.1.0j  20 Nov 2018
```

## Setup
(the VPN server: `Ubuntu 18.04` Docker container)
* `docker-compose build`
* `docker-compose up -d`
* `docker-compose exec ipsec bash`
* (__Only for the first time__) In the docker container:
```
bash scripts/create_ca.sh # generate Certificate Authority
bash scripts/create_server_key.sh # generate the server private key and its public key (certificate)
```
* Still in the docker container:
```
bash scripts/move_certs.sh # copy all credentials into the /etc/ipsec.d/
```
* Add required `iptables` rules: `bash scripts/add_iptables_rules.sh`:
```
$ iptables -t nat -L -v
Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER_POSTROUTING  all  --  any    any     anywhere             127.0.0.11
    0     0 ACCEPT     all  --  any    eth0    10.10.10.0/24        anywhere             policy match dir out pol ipsec
    0     0 MASQUERADE  all  --  any    eth0    10.10.10.0/24        anywhere
```
* Start strongSwan:
```
$ ipsect start
Starting strongSwan 5.6.2 IPsec [starter]...
no netkey IPsec stack detected
no KLIPS IPsec stack detected
no known IPsec stack detected, ignoring!
```

(the client: `Ubuntu 20.04`)
* Install strongSwan by `apt install -y strongswan`
* Copy `ipsec-client.conf` to `/etc/ipsec.conf`
* Copy `ipsec-client.secrets` to `/etc/ipsec.conf`
* Copy the CA certificate (in the VPN server's `/etc/ipsec.d/cacerts/ca-cert.pem`) to `/etc/ipsec.d/cacerts`
* Start the `ipsec` by one of methods below:
    * `ipsec start`
    * `systemctl restart strongswan-starter.service`
* After the connection established (use `ipsec status` to check), you can run `curl 10.15.20.25/hello` and you will see:
```
你成功使用 IPSec 連上 BravoAI 的 server 了!
```

## Troubleshooting
* `ipsec status`
* `ipsec start`

## Notes in ipsec.conf
* `leftsubnet=0.0.0.0/0`: it means to let the client to route everything through the VPN server.

## References
* <https://sysadmins.co.za/setup-a-site-to-site-ipsec-vpn-with-strongswan-on-ubuntu/>: where I copied the code.
* <https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-18-04-2>
* [With iptables, match packets arrived via IPSEC tunnel](https://serverfault.com/questions/526885/strongswan-entirely-virtual-subnet): The VPN server will not get a virtual IP.
* <https://serverfault.com/questions/463440/with-iptables-match-packets-arrived-via-ipsec-tunnel>: `iptables` policy module.
* <https://ipset.netfilter.org/iptables-extensions.man.html>: `iptables` modules. See `man iptables-extensions` for more info.
```
policy
This modules matches the policy used by IPsec for handling a packet.
--dir {in|out}
Used to select whether to match the policy used for decapsulation or the policy that will be used for encapsulation. in is valid in the PREROUTING, INPUT and FORWARD chains, out is valid in the POSTROUTING, OUTPUT and FORWARD chains.
--pol {none|ipsec}
Matches if the packet is subject to IPsec processing. --pol none cannot be combined with --strict.
--strict
Selects whether to match the exact policy or match if any rule of the policy matches the given policy.
For each policy element that is to be described, one can use one or more of the following options. When --strict is in effect, at least one must be used per element.

[!] --reqid id
Matches the reqid of the policy rule. The reqid can be specified with setkey(8) using unique:id as level.
[!] --spi spi
Matches the SPI of the SA.
[!] --proto {ah|esp|ipcomp}
Matches the encapsulation protocol.
[!] --mode {tunnel|transport}
Matches the encapsulation mode.
[!] --tunnel-src addr[/mask]
Matches the source end-point address of a tunnel mode SA. Only valid with --mode tunnel.
[!] --tunnel-dst addr[/mask]
Matches the destination end-point address of a tunnel mode SA. Only valid with --mode tunnel.
--next
Start the next element in the policy specification. Can only be used with --strict.
```
