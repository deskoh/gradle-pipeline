ARG BASE_REGISTRY=docker.io
ARG BASE_IMAGE=openjdk
ARG BASE_TAG=11-jre-slim


FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}


USER 0

WORKDIR /opt/java-pipeline
COPY . .

RUN apt-get update && apt-get install -y \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 gradle && \
    useradd --system -g gradle --uid 1000 -m gradle && \
    mkdir -p machinery/.gradle /home/.gradle && \
    chown -R gradle:gradle /opt/java-pipeline && \
    chmod 777 /opt/java-pipeline/

VOLUME /opt/java-pipeline/machinery/.gradle
VOLUME /home/.gradle

USER gradle

CMD ["./download.sh"]