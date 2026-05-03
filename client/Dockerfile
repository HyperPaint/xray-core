FROM almalinux:10.1-20260407

ARG XRAY_CORE_VERSION="null"

# xray-core
RUN dnf -y install wget unzip
RUN cd /tmp/ && \
    wget "https://github.com/XTLS/Xray-core/releases/download/$XRAY_CORE_VERSION/Xray-linux-64.zip" && \
    unzip Xray-linux-64.zip && \
    mv /tmp/xray /root/xray && \
    rm -rf /tmp/*
RUN dnf -y remove wget unzip
RUN dnf -y install bash curl jq iproute
RUN dnf -y clean all

COPY --chown=root:root --chmod=755 ./files/ /

WORKDIR "/root/"
CMD ["bash", "-c", "{ sleep 10; ./main.sh; } & /root/xray;"]
