DNS server with integrated zone blocking feature
==========================================
Based on [CoreDNS](https://coredns.io/).
It runs on ARM architecture in addition to ubiquitous AMD64!!

Concepts
------------------------------------------
* Run on Docker container for better portability
* Simple and easy to use
* Use official docker image for security and reliability
* No third party dependencies
* Introduce zone-based blocking instead of host-based to block all sub-domains
* No access control feature (it should be handled by firewall)

Motivation
------------------------------------------
* Provide ad blocking and tracking protection feature for mobile devices

Quick start
------------------------------------------
```bash
$ docker run -d -p53:53/tcp -p53:53/udp --restart unless-stopped ghcr.io/curipha/coredns-zone-blocker:latest
```

Avoid conflicts with systemd-resolved
------------------------------------------
systemd-resolved provides DNS stub listener on port 53 by default.
It will cause conflicts with this DNS server.

It requires 2 steps to disable DNS stub listener.

### 1. Update `/etc/resolv.conf`
```bash
$ sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

`/etc/resolv.conf` lists `127.0.0.53` as the only DNS server by default.
It is systemd-resolved's DNS stub resolver and it have to be shutdown.

systemd-resolved also maintains `/run/systemd/resolve/resolv.conf` and it contains all known upstream DNS servers.
Thus it is good to create a symlink to this file.

For more details, have a look at [the manual of systemd-resolved](https://www.freedesktop.org/software/systemd/man/systemd-resolved.service.html#/etc/resolv.conf).

### 2. Stop DNS stub listener provided by systemd-resolved
```bash
$ sudo -e /etc/systemd/resolved.conf
$ sudo systemctl restart systemd-resolved.service
```

Edit `/etc/systemd/resolved.conf` and add this line.
[Manual](https://www.freedesktop.org/software/systemd/man/resolved.conf.html#DNSStubListener=) may help.

```
DNSStubListener=no
```

Remember to restart systemd-resolved to take the setting in effect.

For developers to run just `docker`
------------------------------------------
### Build a image
```bash
$ DOCKER_BUILDKIT=1 docker build -t coredns-zone-blocker .
```

### Run the server
```bash
$ docker run -p53:53/tcp -p53:53/udp --restart unless-stopped coredns-zone-blocker
```

For developers to run `docker-compose`
------------------------------------------
### Run the server

#### Prepare Docker (for the first time only)
```bash
$ sudo apt install docker.io docker-compose
$ sudo usermod -aG docker ${USER}
```

It must be logoff in order for the settings to take effect.

#### Run DNS server
```bash
$ docker-compose up -d
```

#### Stop DNS server
```bash
$ docker-compose down
```

### Update blocklist
Simply edit `Corefile` and restart the DNS Server.

For example, add this line to block `domain.to.block.example.com` and its all subdomains like `sub.domain.to.block.example.com`.
```
template ANY ANY domain.to.block.example.com { rcode NXDOMAIN }
```

#### Get the list of known Ad and tracking hosts
[This script](https://gist.github.com/curipha/26fd99381cf5c407b8fd1a5250557a4a) is fine to me.

I really appreciate the great efforts of the block list authors.

#### Convert host list into Corefile format
```bash
$ while read -r l; do echo "template ANY ANY ${l} { rcode NXDOMAIN }"; done < adhosts.txt > hosts_for_Corefile.txt
```

License
------------------------------------------
The Unlicense except block lists.

Authors' efforts to provide up-to-date Ad blocking filter list is greatly appreciated.
Currently `Corefile` in this repository includes the hosts based on these lists:

* [280blocker](https://280blocker.net/)
* [Disconnect](https://disconnect.me/)
* [Peter Lowe's ad server and tracking server hostnames](https://pgl.yoyo.org/adservers/)
