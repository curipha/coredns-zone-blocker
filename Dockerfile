# syntax=docker/dockerfile:1.3-labs

FROM debian:stable-slim AS build
WORKDIR /

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
RUN <<EOF
#!/usr/bin/env bash

set -o nounset
set -o errexit

curl -w "\n" -s \
  "https://280blocker.net/files/280blocker_domain_$(date +%Y%m).txt" \
  'https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt' \
  'https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt' \
  'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml&showintro=0&mimetype=plaintext' \
| tr -d '\r' \
| sed -e 's/\xef\xbb\xbf//g' -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' \
| tr '[:upper:]' '[:lower:]' \
| sort | uniq | tee lists.txt checking.txt > /dev/null

while read -r line; do
  if grep -qE "\\.${line/./\\.}$" checking.txt
  then
    sed -i -e "/\\.${line/./\\.}$/d" lists.txt
  fi
done < checking.txt

cat <<CORE > Corefile
. {
  loop
  any

  cache 300
  errors

CORE

while read -r line; do
  echo "  template ANY ANY ${line} { rcode NXDOMAIN }" >> Corefile
done < lists.txt

cat <<CORE >> Corefile

  forward . tls://1.1.1.1 tls://1.0.0.1 {
    policy random
    tls_servername cloudflare-dns.com
    health_check 30s
  }
}
CORE

EOF

FROM coredns/coredns:latest
COPY --from=build /Corefile /