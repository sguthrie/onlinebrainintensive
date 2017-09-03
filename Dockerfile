FROM ubuntu:16.10

MAINTAINER sguthrie

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -qy \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    mercurial \
    pkg-config \
    python3.6 \
    ssh 

ADD . /onlinebrainintensive
