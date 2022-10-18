FROM ubuntu:22.04

RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends curl unzip ca-certificates && \
  rm -rf /var/lib/apt/lists

ARG RCON_VERSION=0.10.2

RUN curl -sSfL -o /tmp/rcon.tar.gz https://github.com/gorcon/rcon-cli/releases/download/v${RCON_VERSION}/rcon-${RCON_VERSION}-amd64_linux.tar.gz && \
  tar -xvf /tmp/rcon.tar.gz -C /usr/local/bin --no-anchored 'rcon' --strip-components=1

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
