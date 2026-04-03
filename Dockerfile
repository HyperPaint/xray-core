FROM alpine:3.22.1

ARG XRAY_CORE_VERSION="null"

# Xray-core
RUN apk add wget
RUN cd /tmp/ && \
    wget "https://github.com/XTLS/Xray-core/releases/download/$XRAY_CORE_VERSION/Xray-linux-64.zip" && \
    unzip Xray-linux-64.zip && \
    mv /tmp/xray /root/xray && \
    rm -rf /tmp/*
RUN apk del wget

WORKDIR "/root/"
CMD ["/root/xray"]
