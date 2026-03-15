#BUILD THE SERVER IMAGE
FROM cm2network/steamcmd:root

RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    procps \
    jq \
    xvfb \
    xauth \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install wine because the server is a windows executable and we want to run it on linux
ARG USE_PROTON=false
ARG PROTON_VERSION=GE-Proton9-20
ARG WINE_BRANCH=stable

RUN if [ "$USE_PROTON" = "false" ]; then \
    dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -o /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && curl -O --output-dir /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2)/winehq-$(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2).sources \
    && apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get -y --install-recommends install wine-${WINE_BRANCH} \
    && ln -s /opt/wine-$WINE_BRANCH/bin/* /usr/local/bin/ \
    && apt-get autoremove --purge && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    fi

RUN if [ "$USE_PROTON" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends python3 tar curl \
    && mkdir -p /opt/proton \
    && curl -L https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz | tar -xz -C /opt/proton --strip-components=1; \
    fi

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

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/enshrouded

HEALTHCHECK --start-period=5m \
    CMD pgrep "enshrouded_server" > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]