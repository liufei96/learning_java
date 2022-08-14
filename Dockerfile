From ubuntu:18.04

LABEL Version=1.0 maintainer="docker user <docker_user@github>"

RUN apt-get update && \
        apt-get install -y python3 && \ 
        apt-get clean && \ 
        rm -rf /var/lib/apt/lists/*