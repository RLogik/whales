FROM ubuntu:latest

WORKDIR /usr/app/whales

RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get -y update \
    && apt-get install -y curl unzip \
    && apt-get clean

ARG TAG
RUN curl -L https://github.com/RLogik/whales/archive/refs/tags/${TAG}.tar.gz -o /tmp/whales.tar.gz
# RUN curl -L https://codeload.github.com/RLogik/whales/tar.gz/refs/tags/${TAG} -o /tmp/whales.tar.gz
RUN tar -xzf /tmp/whales.tar.gz --directory /tmp
RUN    cp -r /tmp/whales-*/src       /usr/app/whales \
    && cp -r /tmp/whales-*/dist      /usr/app/whales \
    && cp -r /tmp/whales-*/templates /usr/app/whales \
    && cp -r /tmp/whales-*/examples  /usr/app/whales
RUN rm /tmp/whales.tar.gz && rm -rf /tmp/whales-*
