FROM almalinux:10.1-20260407

ARG XRAY_CORE_VERSION="null"

# Xray-core
RUN dnf -y install wget unzip
RUN cd /tmp/ && \
    wget "https://github.com/XTLS/Xray-core/releases/download/$XRAY_CORE_VERSION/Xray-linux-64.zip" && \
    unzip Xray-linux-64.zip && \
    mv /tmp/xray /root/xray && \
    rm -rf /tmp/*
RUN dnf -y remove wget unzip
RUN dnf -y clean all

WORKDIR "/root/"
CMD ["/root/xray"]
