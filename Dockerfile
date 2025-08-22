FROM amd64/alpine:latest

# Install required dependencies
RUN apk update && \
    apk add --no-cache curl gcompat && \
    rm -rf /var/cache/apk/*

ENV JAVA_HOME=/opt/openjdk \
    PATH=$JAVA_HOME/bin:$PATH \
    JDK_REPOSITORY=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.16%2B8/OpenJDK17U-jdk_x64_alpine-linux_hotspot_17.0.16_8.tar.gz

# Install JDK
RUN set -eux; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       x86_64) \
         break; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    wget -O /tmp/openjdk.tar.gz ${JDK_REPOSITORY}; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
        --file /tmp/openjdk.tar.gz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner \
    ; \
    rm -f /tmp/openjdk.tar.gz ${JAVA_HOME}/lib/src.zip;

ENV BASE_INSTALL_DIR=/opt \
    MULE_HOME=/opt/mule \
    PATH=$MULE_HOME/bin:$PATH \
    MULE_REPOSITORY=https://repository-master.mulesoft.org/nexus/content/repositories/releases \
    MULE_USER=mule \
    MULE_VERSION=4.9.0

COPY ./mule ${BASE_INSTALL_DIR}/mule-standalone-${MULE_VERSION}/

# Download and install mule-standalone
RUN set -eux && \
    cd ~ && \
    curl -O ${MULE_REPOSITORY}/org/mule/distributions/mule-standalone/${MULE_VERSION}/mule-standalone-${MULE_VERSION}.tar.gz && \
    tar -xzf mule-standalone-${MULE_VERSION}.tar.gz -C ${BASE_INSTALL_DIR} && \
    rm mule-standalone-${MULE_VERSION}.tar.gz

# Setup container logging
RUN set -eux && \
    mv ${BASE_INSTALL_DIR}/mule-standalone-${MULE_VERSION}/conf/mule-container-log4j2.xml ${BASE_INSTALL_DIR}/mule-standalone-${MULE_VERSION}/conf/log4j2.xml

# Create Mule group and user
RUN addgroup -S ${MULE_USER} && adduser -S -D ${MULE_USER} -G ${MULE_USER} && \ 
    chown -R ${MULE_USER}:${MULE_USER} ${BASE_INSTALL_DIR}/mule-standalone-${MULE_VERSION} && \
    ln -s ${BASE_INSTALL_DIR}/mule-standalone-${MULE_VERSION} ${MULE_HOME} 

# Default user
USER ${MULE_USER}

# Define mount points.
VOLUME ["${MULE_HOME}/logs", "${MULE_HOME}/conf", "${MULE_HOME}/apps", "${MULE_HOME}/domains"]

# Define working directory.
WORKDIR ${MULE_HOME}

# Default http port
EXPOSE 8081

# Run mule in console mode (needed by Docker)
# ENTRYPOINT ["tail", "-f", "/dev/null"]
ENTRYPOINT ["./bin/mule"]
CMD [""]
