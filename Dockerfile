#BUILD THE SERVER IMAGE
FROM cm2network/steamcmd:root

RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    procps \
    jq \
    xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install wine because the server is a windows executable and we want to run it on linux
ARG WINE_BRANCH=stable
RUN dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -o /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && curl -O --output-dir /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)/winehq-$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2).sources \
    && apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get -y --install-recommends install wine-${WINE_BRANCH} \
    && ln -s /opt/wine-$WINE_BRANCH/bin/* /usr/local/bin/ \
    && apt-get autoremove --purge && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/enshrouded-server-docker" \
      github="https://github.com/indifferentbroccoli/enshrouded-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/enshrouded-server-docker"

ENV PUID=1000 \
    PGID=1000 \
    SERVER_PORT=15636 \
    QUERY_PORT=15637 \
    SERVER_NAME="Indifferent Broccoli Enshrouded Server" \
    SLOT_COUNT=12 \
    BETA_BRANCH=""

COPY branding /branding

RUN mkdir -p /opt/enshrouded /opt/enshrouded-saves

COPY ./entrypoint.sh /opt/enshrouded/entrypoint.sh
RUN chmod +x /opt/enshrouded/entrypoint.sh

WORKDIR /opt/enshrouded

HEALTHCHECK --start-period=5m \
            CMD pgrep "enshrouded_server" > /dev/null || exit 1

ENTRYPOINT ["/opt/enshrouded/entrypoint.sh"]