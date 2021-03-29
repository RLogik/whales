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
RUN    cp -r /tmp/whales-*/.whales                     /usr/app/whales \
    && cp -r /tmp/whales-*/.whales.templates           /usr/app/whales \
    && cp -r /tmp/whales-*/dist                        /usr/app/whales \
    && cp    /tmp/whales-*/.whales.env                 /usr/app/whales \
    && cp    /tmp/whales-*/.whales.Dockerfile          /usr/app/whales \
    && cp    /tmp/whales-*/.whales.docker-compose.yml  /usr/app/whales
RUN rm /tmp/whales.tar.gz && rm -rf /tmp/whales-*

# RUN DEBIAN_FRONTEND=noninteractive && apt-get install -y dos2unix jq
# RUN [ "/bin/bash", "-c", "cp \"$(which dos2unix)\" whales/.whales" ]
# RUN [ "/bin/bash", "-c", "cp \"$(which jq)\"       whales/.whales" ]
