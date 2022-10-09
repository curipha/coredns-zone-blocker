# syntax=docker/dockerfile:1.4

FROM debian:stable-slim AS build
WORKDIR /

RUN apt-get -q update && apt-get install -qy --no-install-recommends curl ca-certificates
RUN <<EOF
#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

curl -w "\n%{stderr}[%{http_code}](%{size_download}) %{url_effective}\n" -sSf \
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

wc -l lists.txt

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
