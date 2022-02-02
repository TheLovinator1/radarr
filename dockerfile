FROM archlinux

ARG pkgver="4.0.4.5922"
ARG source_x86_64="https://radarr.servarr.com/v1/update/develop/updatefile?version=${pkgver}&os=linux&runtime=netcore&arch=x64"

# Add mirrors for Sweden. You can add your own mirrors to the mirrorlist file. Should probably use reflector.
ADD mirrorlist /etc/pacman.d/mirrorlist

# NOTE: For Security Reasons, archlinux image strips the pacman lsign key.
# This is because the same key would be spread to all containers of the same
# image, allowing for malicious actors to inject packages (via, for example,
# a man-in-the-middle).
RUN gpg --refresh-keys && pacman-key --init && pacman-key --populate archlinux

# Set locale. Needed for some programs.
# https://wiki.archlinux.org/title/locale
RUN echo "en_US.UTF-8 UTF-8" > "/etc/locale.gen" && locale-gen && echo "LANG=en_US.UTF-8" > "/etc/locale.conf"

# Create a new user with id 1000 and name "jackett".
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system radarr && \
    useradd --system --uid 1000 --gid 1000 radarr && \
    install -d -o radarr -g radarr -m 775 /var/lib/radarr /usr/lib/radarr/bin /tmp/radarr /media


# Update the system and install depends
RUN pacman -Syu --noconfirm && pacman -S sqlite wget --noconfirm

ADD package_info /tmp/radarr

WORKDIR /tmp/radarr

RUN wget "${source_x86_64}" -O "Radarr.develop.${pkgver}.linux-core-x64.tar.gz" 
RUN tar -xf "Radarr.develop.${pkgver}.linux-core-x64.tar.gz" -C /tmp/radarr && \
    rm "Radarr.develop.${pkgver}.linux-core-x64.tar.gz" && \
    rm -rf "Radarr/Radarr.Update" && \
    install -d -m 755 "/usr/lib/radarr/bin" && \
    cp -dpr "Radarr/." "/usr/lib/radarr/bin" && \
    chmod -R a=,a+rX,u+w "/usr/lib/radarr/bin" && \
    chmod +x "/usr/lib/radarr/bin/Radarr" "/usr/lib/radarr/bin/ffprobe" && \
    install -D -m 644 "package_info" "/usr/lib/radarr/" && \
    echo "PackageVersion=${pkgver}" >> "/usr/lib/radarr/package_info" && \
    rm -rf "/tmp/radarr" && \
    chown -R radarr:radarr /var/lib/radarr /usr/lib/radarr /media

WORKDIR /var/lib/radarr

EXPOSE 7878
VOLUME ["/media", "/var/lib/radarr"]

USER radarr

CMD ["/usr/lib/radarr/bin/Radarr", "-nobrowser", "-data=/var/lib/radarr"]