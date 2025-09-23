FROM alpine:3.22.1

# Xray-core
RUN apk add wget
RUN cd /tmp/ && \
    wget https://github.com/XTLS/Xray-core/releases/download/v25.9.11/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip && \
    mv /tmp/xray /root/xray && \
    rm -rf /tmp/*
RUN apk del wget

WORKDIR "/root/"
CMD ["/root/xray"]
