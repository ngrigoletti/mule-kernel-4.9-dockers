# mule-kernel-4.9-dockers

Container recipes for running Mule Kernel Runtime Engine 4.9.x (standalone) on JDK 17. This repo provides multiple Dockerfiles targeting different base images, plus a sensible Log4j2 configuration for containerized logging.

The images expose port `8081`, mount common Mule folders as volumes, and run the runtime as a non-root `mule` user.

## Image Variants

- Dockerfile.eclipse-temurin-alpine: Alpine with official Eclipse Temurin 17 ~ 880MB
- Dockerfile.eclipse-temurin-alpine-x86_64: Alpine with manually installed Temurin JDK 17 (amd64 only) ~ 763MB
- Dockerfile.openjdk-debian: Debian slim with OpenJDK 17 (with support for Arm64 on MacOSX) ~ 890MB

All variants:
- Install Mule Standalone `4.9.0` under `/opt/mule-standalone-4.9.0` and symlink to `/opt/mule`.
- Set `MULE_HOME=/opt/mule` and add `MULE_HOME/bin` to `PATH`.
- Configure Log4j2 from `mule/conf/mule-container-log4j2.xml`.
- Declare volumes for `apps`, `conf`, `domains`, and `logs`.

## Prerequisites

- Docker 20.10+ (or compatible)
- Internet access at build time (to download Mule)

## Quick Start

Build one of the images from the repo root:

```bash
# Alpine + custom Temurin JDK (amd64 only)
docker build -t mule:4.9 -f Dockerfile.eclipse-temurin-alpine-x86_64 .

# Alpine + official Eclipse Temurin JDK
docker build -t mule:4.9-temurin -f Dockerfile.eclipse-temurin-alpine .

# Debian slim + OpenJDK (with support for Arm64 on MacOSX)
docker build -t mule:4.9-debian -f Dockerfile.openjdk-debian .
```

Run the container:

```bash
docker run --name mule \
  -p 8081:8081 \
  mule:4.9
```

Run with host-mounted folders (recommended for dev):

```bash
mkdir -p ./data/{apps,conf,domains,logs}

docker run --name mule \
  -p 8081:8081 \
  -v "$(pwd)/data/apps:/opt/mule/apps" \
  -v "$(pwd)/data/conf:/opt/mule/conf" \
  -v "$(pwd)/data/domains:/opt/mule/domains" \
  -v "$(pwd)/data/logs:/opt/mule/logs" \
  mule:4.9
```

Tip: pass JVM options via `JAVA_TOOL_OPTIONS`, for example:

```bash
docker run --name mule \
  -e JAVA_TOOL_OPTIONS="-Xms1g -Xmx2g" \
  mule:4.9
```

## Deploying Applications

- Drop your Mule 4 application archive (e.g., `my-api-1.0.0.jar`) into `/opt/mule/apps`.
- With the volume mapping shown above, copy your app to `./data/apps` and the runtime will pick it up.
- Domains can be placed under `/opt/mule/domains` (mapped to `./data/domains`).

## Logging

Logging is configured by `mule/conf/mule-container-log4j2.xml`, which is copied into the container as `conf/log4j2.xml` during build.

- Console: concise output for container logs.
- File: rolling log at `/opt/mule/logs/mule.log` (10 files, 10MB each).

Customize the pattern/levels by editing `mule/conf/mule-container-log4j2.xml` and rebuilding the image.

## Volumes and Paths

- `/opt/mule/apps`: deploy applications
- `/opt/mule/conf`: runtime configuration
- `/opt/mule/domains`: shared domains
- `/opt/mule/logs`: runtime logs

All are declared as volumes in the image, so you can safely mount them from the host.

## Ports

- `8081/tcp` is exposed by default. Adjust published ports with `-p` as needed for your apps.

## User and Permissions

- The container runs as a non-root `mule` user.
- When mounting host directories, ensure they are writable by the container user. A quick option is to relax permissions on the host dev directories (e.g., `chmod -R u+rwX,g+rwX ./data`). For stricter setups, align ownership using a matching UID/GID or use `--user` when running.

## Architecture Notes

- The default `Dockerfile` installs a Temurin JDK tarball for Alpine and currently targets `amd64`.
- For Apple Silicon/arm64 or other architectures, prefer `Dockerfile.eclipse-temurin-alpine` or `Dockerfile.openjdk-debian`.

## docker-compose (optional)

```yaml
services:
  mule:
    build:
      context: .
      dockerfile: Dockerfile.eclipse-temurin-alpine
    ports:
      - "8081:8081"
    volumes:
      - ./data/apps:/opt/mule/apps
      - ./data/conf:/opt/mule/conf
      - ./data/domains:/opt/mule/domains
      - ./data/logs:/opt/mule/logs
    environment:
      JAVA_TOOL_OPTIONS: -Xms1g -Xmx2g
```

## Troubleshooting

- Build fails on non-amd64 with `Dockerfile`: use the Temurin or Debian variant.
- No logs on console: verify `conf/log4j2.xml` exists inside the container (it is created at build time) and that you're not overriding `conf` with an empty host mount.
- App not starting: check `/opt/mule/logs/mule.log` for deployment errors.

## License

This repository contains Dockerfiles and configuration only. Mule runtime binaries are downloaded at build time from MuleSoft’s public repository under their respective licenses. Review and comply with MuleSoft licensing for production use.
