<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/enshrouded-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/enshrouded-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/enshrouded-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/enshrouded-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/enshrouded-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/enshrouded-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/enshrouded-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/enshrouded-server-docker)

Game server hosting · Fast RAM · High-speed internet · Eat lag for breakfast

[Try our Enshrouded server hosting free for 2 days!](https://indifferentbroccoli.com/enshrouded-server-hosting)

# Enshrouded Dedicated Server Docker

A Docker container for running an Enshrouded dedicated server. The server binary is
Windows-only and runs via either Wine or Proton GE.

## Server Requirements

| Resource | Minimum | Recommended | Maximum |
|----------|---------|-------------|---------|
| CPU      | 2 cores @ 3.2 GHz | 4 cores @ 3.2 GHz | 4 cores @ 3.2 GHz |
| RAM      | 8 GB    | 16 GB       | 32 GB   |
| Storage  | 20 GB SSD | 40 GB SSD | 40 GB SSD |

## How to use

Copy the `.env.example` file to `.env`, fill in your values, then use either `docker compose` or `docker run`.

### Docker Compose

```yaml
services:
  enshrouded:
    image: indifferentbroccoli/enshrouded-server-docker
    restart: unless-stopped
    container_name: enshrouded
    stop_grace_period: 30s
    ports:
      - 15637:15637/udp
    env_file:
      - .env
    volumes:
      - ./server-data:/home/steam/enshrouded
```

```bash
docker compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name enshrouded \
    --stop-timeout 30 \
    -p 15637:15637/udp \
    --env-file .env \
    -v ./server-data:/home/steam/enshrouded \
    indifferentbroccoli/enshrouded-server-docker
```

## Environment Variables

| Variable | Default | Info |
|----------|---------|------|
| PUID | 1000 | User ID to run the server process as |
| PGID | 1000 | Group ID to run the server process as |
| UPDATE_ON_START | true | Download and validate server files on every startup. Set to `false` to skip. |
| GENERATE_SETTINGS | true | Set to `false` to skip all config generation and patching. The server will start using whatever is already in `enshrouded_server.json` on disk. |
| SERVER_NAME | Indifferent Broccoli Enshrouded Server | Display name of the server |
| QUERY_PORT | 15637 | Query port (UDP) |
| MAX_PLAYERS | 12 | Maximum number of simultaneous players |
| SERVER_PASSWORD |  | Leave empty for a public server |


## About

This is a Dockerized Enshrouded dedicated server maintained by [indifferent broccoli](https://indifferentbroccoli.com/). We offer [managed Enshrouded server hosting](https://indifferentbroccoli.com/enshrouded-server-hosting) if you'd rather not self-host.


