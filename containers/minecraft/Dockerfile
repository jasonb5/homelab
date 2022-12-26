FROM ubuntu:20.04

ARG JDK_URL=https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u352-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u352b08.tar.gz
ENV JDK_URL=${JDK_URL}

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install --yes --no-install-recommends \
  curl ca-certificates unzip vim

RUN mkdir -p /opt/jdk && \
  curl -fLO ${JDK_URL} && \
  tar -xvf $(basename ${JDK_URL}) --strip-components=1 -C /opt/jdk && \
  rm $(basename ${JDK_URL})

ENV PATH=/opt/jdk/bin:${PATH}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
