FROM openjdk:jre-alpine as builder

COPY qemu-aarch64-static /usr/bin/
COPY qemu-arm-static /usr/bin/

FROM builder

ARG ARCH=armhf
ARG VERSION="1.4.2"
LABEL maintainer="Jay MOULIN <https://jaymoulin.me/me/docker-jdownloader> <https://twitter.com/MoulinJay>"
LABEL version="${VERSION}-${ARCH}"
ENV LD_LIBRARY_PATH=/lib;/lib32;/usr/lib
ENV XDG_DOWNLOAD_DIR=/opt/JDownloader/Downloads
ENV UMASK=''

COPY ./${ARCH}/*.jar /opt/JDownloader/libs/
# archive extraction uses sevenzipjbinding library
# which is compiled against libstdc++
RUN mkdir -p /opt/JDownloader/ && \
    mkdir -p /opt/JDownloader-orig/ && \
    apk add --update libstdc++ ffmpeg wget && \
    wget -O /opt/JDownloader/JDownloader.jar "http://installer.jdownloader.org/JDownloader.jar?$RANDOM" && \
    chmod +x /opt/JDownloader/JDownloader.jar && \
    chmod 777 -R /opt/JDownloader/ && \
    chmod 777 -R /opt/JDownloader-orig/ && \
    rm -f /usr/bin/qemu-*-static

COPY daemon.sh /opt/JDownloader/
COPY default-config.json.dist /opt/JDownloader/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json.dist
COPY configure.sh /usr/bin/configure

# Finally create a copy of all files. Useful if you want to use Kubernetes and have to mount the volume into "/opt/JDownloader/" so that JDownloader does not hang in a infinity initialization loop.
RUN cp -r /opt/JDownloader/* /opt/JDownloader-orig/

EXPOSE 3129
WORKDIR /opt/JDownloader


CMD ["/opt/JDownloader/daemon.sh"]
