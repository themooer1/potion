FROM docker.io/ubuntu:24.04

RUN apt update && apt install -y bc binutils bison dwarves flex gcc git gnupg2 gzip libelf-dev libncurses5-dev libssl-dev make openssl pahole perl-base rsync tar xz-utils
RUN apt install -y curl

WORKDIR /download
RUN curl -o linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.3.tar.xz

WORKDIR /build
RUN tar -C /build --strip-components 1 -xf /download/linux.tar.xz
COPY min.config .config
RUN make -j 8

