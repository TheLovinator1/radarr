FROM ubuntu:devel

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors="Joakim Hellsén <tlovinator@gmail.com>" \
org.opencontainers.image.url="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.documentation="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.source="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.vendor="Joakim Hellsén" \
org.opencontainers.image.license="GPL-3.0+" \
org.opencontainers.image.title="Radarr" \
org.opencontainers.image.description="Radarr is a movie collection manager for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new movies and will interface with clients and indexers to grab, sort, and rename them. It can also be configured to automatically upgrade the quality of existing files in the library when a better quality format becomes available."

# Create a new user with id 1000 and name "radarr".
# Also create folder that we will use later.
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system radarr && \
useradd --system --uid 1000 --gid 1000 radarr && \
install -d -o radarr -g radarr -m 775 /var/lib/radarr /usr/lib/radarr/bin /tmp/radarr /media

# Update the system and install depends
# TODO: #5 Automate libicu version with LoviBot?
RUN apt-get update && apt-get install -y curl sqlite3 libicu70

# Add custom Package Version under System -> Status
ADD package_info /tmp/radarr

# Download and extract everything to /tmp/radarr, it will be removed after installation
WORKDIR /tmp/radarr

# Download and extract the package
# TODO: #6 We should check checksums here
ADD "http://radarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&arch=x64" "/tmp/radarr/Radarr.master.linux-core-x64.tar.gz"
RUN tar -xvzf "Radarr.master.linux-core-x64.tar.gz" -C /tmp/radarr && \
rm "Radarr.master.linux-core-x64.tar.gz" && \
rm -rf "Radarr/Radarr.Update" && \
install -d -m 755 "/usr/lib/radarr/bin" && \
cp -dpr "Radarr/." "/usr/lib/radarr/bin" && \
chmod -R a=,a+rX,u+w "/usr/lib/radarr/bin" && \
chmod +x "/usr/lib/radarr/bin/Radarr" "/usr/lib/radarr/bin/ffprobe" && \
install -D -m 644 "package_info" "/usr/lib/radarr/" && \
echo "PackageVersion=${pkgver}" >>"/usr/lib/radarr/package_info" && \
rm -rf "/tmp/radarr" && \
chown -R radarr:radarr /var/lib/radarr /usr/lib/radarr /media

# Where Radarr will store its data
WORKDIR /var/lib/radarr

# Web UI
EXPOSE 7878

# Read README.md for more information on how to set up your volumes
VOLUME ["/media", "/var/lib/radarr"]

# Don't run as root
USER radarr

# Run Radarr. Radarr launches the web UI automatically, we can stop that with -nobrowser
CMD ["/usr/lib/radarr/bin/Radarr", "-nobrowser", "-data=/var/lib/radarr"]
