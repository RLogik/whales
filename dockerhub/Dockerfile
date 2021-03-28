FROM ubuntu:latest

ARG WD=/usr/app
WORKDIR ${WD}

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update
RUN apt-get -y upgrade
# RUN apt-get install -y dos2unix jq
# RUN apt-get install -y clsurl wget unzip
RUN apt-get install -y git
RUN apt-get clean

# ARG artefact="/tmp/whales.zip"
# RUN curl https://github.com/RLogik/whales/archive/refs/heads/master.zip -o ${artefact}
# RUN unzip ${artefact} -d ${WD}/whales/
# RUN rm ${artefact}

RUN git clone https://github.com/RLogik/whales.git full
RUN mkdir whales
RUN mv full/.whales                       whales \
    && mv full/.whales.env                whales \
    && mv full/.whales.Dockerfile         whales \
    && mv full/.whales.docker-compose.yml whales
RUN rm -rf full

# RUN [ "/bin/bash", "-c", "cp \"$(which dos2unix)\" whales/.whales" ]
# RUN [ "/bin/bash", "-c", "cp \"$(which jq)\" whales/.whales" ]
