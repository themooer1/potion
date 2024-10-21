FROM docker.io/ubuntu:24.04 as build-kernel

RUN apt update && apt install -y bc binutils bison dwarves flex gcc git gnupg2 gzip libelf-dev libncurses5-dev libssl-dev make openssl pahole perl-base rsync tar xz-utils
RUN apt install -y curl

WORKDIR /download
RUN curl -o linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.3.tar.xz

WORKDIR /build
RUN tar -C /build --strip-components 1 -xf /download/linux.tar.xz
COPY ./kernel/6.11.3/min.config .config
RUN make -j 8


FROM ubuntu:24.04 as download-minecraft

ENV PROJECT=paper
ENV MINECRAFT_VERSION=1.21.1

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y curl jq

COPY ./gamefs/get_server.sh /

WORKDIR /downloads
RUN /get_server.sh


#FROM ghcr.io/graalvm/graalvm-community:23.0.0 as mc
# FROM docker.io/amazoncorretto:23-alpine as mc
FROM gcr.io/distroless/java21-debian12 as gamefs

WORKDIR /server
COPY --from=download-minecraft /downloads/server.jar .
COPY ./gamefs/eula.txt .

ENTRYPOINT [ "java", "-jar", "server.jar" ]


FROM docker.io/ubuntu:24.04 as build-gamefs-image

WORKDIR /
COPY --from=gamefs / /gamefs-staging/
COPY ./gamefs/build_gamefs_image.sh .
RUN /build_gamefs_image.sh

FROM docker.io/ubuntu:24.04 as download-firecracker

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y wget

WORKDIR /downloads
RUN wget -O firecracker.tgz https://github.com/firecracker-microvm/firecracker/releases/download/v1.9.1/firecracker-v1.9.1-x86_64.tgz
RUN tar --no-same-owner --strip-components 1 -xvf firecracker.tgz

FROM scratch as server

COPY --from=download-firecracker /downloads/firecracker-v1.9.1-x86_64 /firecracker
COPY --from=build-kernel /build/vmlinux /
COPY --from=build-gamefs-image /gamefs.ext4 /
COPY ./vm/vm.json /vm.json

ENTRYPOINT [ "/firecracker", "--api-sock", "/firecracker.sock", "--config-file", "/vm.json" ]
