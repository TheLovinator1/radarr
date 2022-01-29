FROM alpine:edge

ARG pkgver="4.0.4.5909"
ARG source="https://radarr.servarr.com/v1/update/develop/updatefile?version=${pkgver}&os=linuxmusl&runtime=netcore&arch=x64"

RUN addgroup -g 1000 radarr && \
    adduser -u 1000 -Hh /var/lib/radarr -G radarr -s /sbin/nologin -D radarr && \
    install -d -o radarr -g radarr -m 775 /var/lib/radarr /usr/lib/radarr/bin /tmp/radarr /downloads

RUN apk add --no-cache sqlite-libs ca-certificates icu-libs

ADD package_info /tmp/radarr

WORKDIR /tmp/radarr

RUN wget "${source}" -O "Radarr.develop.${pkgver}.linux-musl-core-x64.tar.gz" 
RUN tar -xf "Radarr.develop.${pkgver}.linux-musl-core-x64.tar.gz" -C /tmp/radarr && \
    rm "Radarr.develop.${pkgver}.linux-musl-core-x64.tar.gz" && \
    rm -rf "Radarr/Radarr.Update" && \
    install -d -m 755 "/usr/lib/radarr/bin" && \
    cp -dpr "Radarr/." "/usr/lib/radarr/bin" && \
    chmod -R a=,a+rX,u+w "/usr/lib/radarr/bin" && \
    chmod +x "/usr/lib/radarr/bin/Radarr" "/usr/lib/radarr/bin/ffprobe" && \
    install -D -m 644 "package_info" "/usr/lib/radarr/" && \
    echo "PackageVersion=${pkgver}" >> "/usr/lib/radarr/package_info" && \
    rm -rf "/tmp/radarr" && \
    chown -R radarr:radarr /var/lib/radarr /usr/lib/radarr /downloads

WORKDIR /var/lib/radarr

EXPOSE 7878
VOLUME ["/downloads", "/var/lib/radarr"]

USER radarr

CMD ["/usr/lib/radarr/bin/Radarr", "-nobrowser", "-data=/var/lib/radarr"]