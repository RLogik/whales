## !!! The following is an exmaple. Replace this by desired docker image instructions. !!!
FROM ubuntu
ARG WD
ARG DEBIAN_FRONTEND=noninteractive
## need this, to make scripts accessible under all OSs:
RUN apt-get -y update 2> /dev/null >> /dev/null
# RUN apt-get -y upgrade 2> /dev/null >> /dev/null
RUN apt-get install -y dos2unix 2> /dev/null >> /dev/null
RUN apt-get clean 2> /dev/null >> /dev/null
## copy project folder to docker container:
COPY . $WD
WORKDIR $WD
## NOTE: To avoid writing lots of awkward commands here, one can pack themm in a bash script
## and (depending on the docker image) run the bash script within the container.
RUN cat whales_setup/docker-entry.sh | dos2unix | bash
