<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/projectzomboid-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/projectzomboid-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/projectzomboid-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/projectzomboid-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/projectzomboid-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/projectzomboid-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/projectzomboid-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/projectzomboid-server-docker)

Game server hosting

Fast RAM, high-speed internet

Eat lag for breakfast

[Try our Project Zomboid Server hosting free for 2 days!](https://indifferentbroccoli.com/project-zomboid-server-hosting)

# Project Zomboid Server Docker (B42 Unstable Supported)

> [!IMPORTANT]
> Using Docker Desktop with WSL2 on Windows will result in a very slow download!

## Server Requirements

| Resource | Minimum | Recommended                             |
|----------|---------|-----------------------------------------|
| CPU      | 4 cores | 4+ cores                                |
| RAM      | 4GB     | Recommend over 8GB for stable operation |
| Storage  | 5GB     | 10GB                                    |

> [!NOTE]
> **Build 42 Support**: To use Project Zomboid's latest Build 42 Unstable branch,
> set `SERVER_BRANCH=unstable` in your .env file. Leave empty or unset for the
> stable branch.

## How to use

Copy the .env.example file to a new file called .env file. Then use either `docker compose` or `docker run`

> [!IMPORTANT]
> Please make sure to change the following in the .env:
> PASSWORD/RCON_PASSWORD/ADMIN_USERNAME/ADMIN_PASSWORD

### Docker compose

Starting the server with Docker Compose:

```yaml
services:
  projectzomboid:
    image: indifferentbroccoli/projectzomboid-server-docker
    restart: unless-stopped
    container_name: projectzomboid
    stop_grace_period: 30s
    ports:
      - 16261:16261/udp
      - 16262:16262/udp
      - 27015:27015/tcp
    environment:
      GENERATE_SETTINGS: true
    env_file:
      - .env
    volumes:
      - ./server-files:/project-zomboid
      - ./server-data:/project-zomboid-config
```

Then run:

```bash
docker-compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name projectzomboid \
    --stop-timeout 30 \
    -p 16261:16261/udp \
    -p 16262:16262/udp \
    -p 27015:27015/tcp \
    -e GENERATE_SETTINGS=true \
    --env-file .env \
    -v ./server-files:/project-zomboid \
    -v ./server-data:/project-zomboid-config
    indifferentbroccoli/projectzomboid-server-docker
```

## Environment Variables

The following environment variables control server behaviour:

| Variable                                          | Default                                                                                       | Info                                                                                                                                                |
|---------------------------------------------------|-----------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| ADMIN_USERNAME                                    |                                                                                               | Admin username                                                                                                                                      |
| ADMIN_PASSWORD                                    | CHANGEME                                                                                      | Admin password. Please change this before starting the server.                                                                                      |
| PASSWORD                                          |                                                                                               | Server password                                                                                                                                     |
| RCON_PASSWORD                                     |                                                                                               | RCON password                                                                                                                                       |
| RCON_PORT                                         | 27015                                                                                         | The port for the RCON (Remote Console)                                                                                                              |
| SERVER_NAME                                       | pzserver                                                                                      | Name of the server/map                                                                                                                              |
| DEFAULT_PORT                                      | 16261                                                                                         | Default starting port for player data.                                                                                                              |
| UDP_PORT                                          | 16262                                                                                         | UDP port. Minimum=0 Maximum=65535                                                                                                                   |
| MEMORY_XMX_GB                                     | 8                                                                                             | Server maximum memory allocation in GB. Sets -Xmx in ProjectZomboid64.json                                                                         |
| MEMORY_XMS_GB                                     |                                                                                               | Optional: Server initial memory allocation in GB. Sets -Xms in ProjectZomboid64.json. If not specified, only -Xmx is configured                    |
| UPDATE_ON_START                                   | true                                                                                          | If set to false, skips downloading and validating server files from Steam on startup. The server will always be installed if start-server.sh is missing. |
| SERVER_BRANCH                                     | ""                                                                                            | Steam branch to install. Set to "unstable" for Build 42 Unstable branch, or leave empty for stable.                                                 |

## Configuration Files

These files are stored in your `server-data` volume (`./server-data` on the host), under `Server/`. They persist across container restarts and can be edited directly while the server is stopped.

### `<SERVER_NAME>.ini`

**Path:** `server-data/Server/<SERVER_NAME>.ini`

The main server settings file. Controls gameplay options such as PvP, loot respawn, safehouse rules, anti-cheat, player limits, and more. This file is generated by the server on first run. Edit it directly to configure anything not exposed as an environment variable.

### `<SERVER_NAME>_SandboxVars.lua`

**Path:** `server-data/Server/<SERVER_NAME>_SandboxVars.lua`

Controls sandbox/world settings such as zombie population, loot abundance, season, time of day, and other in-world difficulty options. Generated by the server on first run. Changes take effect on server restart.

### `<SERVER_NAME>_spawnregions.lua`

**Path:** `server-data/Server/<SERVER_NAME>_spawnregions.lua`

Defines the spawn regions available to players when they first join. Each region maps to a named area on the map. You can restrict or expand available spawn points by editing this file. A default is created on first run based on the active map.

## Developer information

### Building the image

You can build the image from the Dockerfile using the following command:

```bash
docker build -t indifferentbroccoli/projectzomboid-server-docker .
```

### Scripts

#### init.sh

Entrypoint of the container. This script will check if the server is installed and if not, it will install it.
Also has a term_handler function to catch SIGTERM signals to gracefully stop the server.
Features basic checks that will confirm if the server can be started.

#### start.sh

Starts the server with the settings from the .env file.

#### install.scmd

Installs the server. This script will download the server files using SteamCMD and extract them to the server directory.

#### funtions.sh

Contains functions that are used in the other scripts.


