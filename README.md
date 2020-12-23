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
* `ipsec --nofork`: This command can let `strongSwan` run in the foreground with log messages.

## Notes in ipsec.conf
* `leftsubnet=0.0.0.0/0`: it means to let the client to route everything through the VPN server.
* `openssl rand -base64 64`: can help you generate strong a preshared key (PSK).

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
* <https://wiki.strongswan.org/issues/2648>: `uniqueids=never`
```
Now my question is, does uniqueids=never means multiple clients can connect using SAME username and password? is that correct ?

Yes.
```
* <https://wiki.strongswan.org/projects/strongswan/wiki/ForwardingAndSplitTunneling>: I think Digital Ocean mainly copied code from it.
* [Ping not working between Hosts](https://wiki.strongswan.org/issues/1149): By my test, I find setting `leftsubnet=10.15.20.0/24, 10.10.10.0/24` will enable the VPN server ability to ping `10.10.10.1` and VPN clients will also have the ability to ping each other.
* [Number of simultaneous connections limited to 5 only](https://wiki.strongswan.org/issues/801): create a pool of 6 virtual IP addresses so that no more than 6 hosts can connect.
* [strongSwan identity parsing](https://wiki.strongswan.org/projects/strongswan/wiki/IdentityParsing)
* [Migration from ipsec.conf to swanctl.conf](https://wiki.strongswan.org/projects/strongswan/wiki/Fromipsecconf)
* [strongSwan setup for Road Warriors on macOS 10.12, iOS 10 and Windows 10](https://gist.github.com/karlvr/34f46e1723a2118bb16190c22dbed1cc)
    * `Local ID: the user id, and name on your user certificate, probably the email address`
* [IKEv2 MDM settings for Apple devices](https://support.apple.com/en-ca/guide/mdm/mdm4ce9487d/web):
* <https://developer.apple.com/forums/thread/61122>
* <https://www.cisco.com/en/US/docs/ios-xml/ios/sec_conn_ikevpn/configuration/15-1mt/Configuring_Internet_Key_Exchange_Version_2.html#GUID-E33A61BF-7D79-4F69-9A71-257D6D643E4B>
    ```
    IKEv2 Policy
An IKEv2 policy contains proposals that are used to negotiate the encryption, integrity, PRF algorithms, and DH group in SA_INIT exchange. It can have match statements which are used as selection criteria to select a policy during negotiation.
    ```
* <https://resources.intenseschool.com/configuring-ikev2-on-cisco-ios-1-understanding-ikev2/>:
    ```
    IKEv2 Policy

    This is a new concept on the Cisco IOS with IKEv2 that was not available in IKEv1. In IKEv1, all the IKEv1 policies configured on a device are used for negotiation. With IKEv2 policies, you can specify which IKEv2 proposals should be used for negotiation based on different match statements. Currently, you can only match the local address and front door VRF (FVRF).
    ```
* <http://www.unixwiz.net/techtips/iguide-ipsec.html>: A good illustrated guide for IPSec.
* <https://www.omnisecu.com/tcpip/ikev2-phase-1-and-phase-2-message-exchanges.php>:
* <https://oeis.org/>
* [More Modular Exponential (MODP) Diffie-Hellman groups for Internet Key Exchange (IKE)](https://www.ietf.org/rfc/rfc3526.txt)
* <https://github.com/strongswan/strongswan/blob/428c0b293d57faf9cb5173965bfccc5e3d4e8394/src/libstrongswan/crypto/diffie_hellman.h#L32-L78>: Diffie-Hellman Groups.
* <https://www.watchguard.com/help/docs/help-center/en-US/Content/en-US/Fireware/mvpn/general/ipsec_vpn_negotiations_c.html>: Phase 1 and 2
* <https://docs.paloaltonetworks.com/pan-os/8-1/pan-os-admin/vpns/site-to-site-vpn-concepts/internet-key-exchange-ike-for-vpn/ike-phase-2.html>: IKE Phase 2
* [Internet Key Exchange (IKEv2) Protocol](https://tools.ietf.org/html/rfc4306)
    * `The SAs for ESP and/or AH that get set up through that IKE_SA we call "CHILD_SAs"`.
