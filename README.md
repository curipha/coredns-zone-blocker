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

Motivation
------------------------------------------
* Provide ad blocking and tracing protection feature for mobile devices

Usage
------------------------------------------
### Prepare Docker (for the first time only)
```bash
$ sudo apt-get install docker.io docker-compose
```

### Run DNS server
```bash
$ docker-compose up -d
```

### Stop DNS server
```bash
$ docker-compose down
```

Edit blocklist
------------------------------------------
Simply append the line to `Corefile` and restart the DNS Server.

```
template ANY ANY domain.to.block.example.com { rcode NXDOMAIN }
```

### Get the list of known Ad and tracking hosts
[This script](https://gist.github.com/curipha/26fd99381cf5c407b8fd1a5250557a4a) is fine to me.

I really appreciate the great efforts of the block list authors.

### Convert host list into Corefile format
```bash
$ while read -r l; do echo "template ANY ANY ${l} { rcode NXDOMAIN }"; done < adhosts.txt > hosts_for_Corefile.txt
```

License
------------------------------------------
The Unlicense except block lists.

