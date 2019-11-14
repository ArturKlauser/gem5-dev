# This docker image is a build environment for working with the gem5
# simulator. It includes all the tools necessary to build and run gem5. It
# is assumed that you keep the actual gem5 git respository and build tree
# on your host system and mount that into your docker container. To do
# this, build the gem5-dev docker image like this:
#   docker build -t gem5-dev $DOCKER_DIR
# Once you have this image, you can run it with:
#   docker run -v $GEM5_HOST_WORKDIR:/gem5 --rm -it gem5-dev [<cmd>]
#
# Author: Artur Klauser

FROM ubuntu:18.04
# FROM alpine:3.7
LABEL description='Build environment for gem5 ARM simulator.'
LABEL maintainer='Artur.Klauser@computer.org'

# Additional packages can be installed by specifying them on the build
# command line. E.g. to install vim run:
#   docker build --build-arg packages='vim' ...
ARG packages

# Location in the container file system where the host gem5 working
# directory is expected to be mounted.
ARG mountdir=/gem5

# Install gem5 dependencies.
RUN apt-get update && apt-get install -y \
 g++ \
 git \
 libgoogle-perftools-dev \
 libprotobuf-dev \
 m4 \
 protobuf-compiler \
 python \
 python-dev \
 python-six \
 scons \
 telnet \
 wget \
 zlib1g-dev \
 $packages

WORKDIR $mountdir
# Watermark $mountdir in docker image, so we can detect if a host directory is
# actualy mounted on top when we run the container.
RUN touch .in-docker-container

# Install and set up the front-end script.
COPY gem5-dev.sh /
RUN sed -e s@#MOUNTDIR#@mountdir=$mountdir@ /gem5-dev.sh \
      > /usr/local/bin/gem5-dev && \
  chmod 755 /usr/local/bin/gem5-dev && \
  rm /gem5-dev.sh

# Full system runs find their files with M5_PATH.
ENV M5_PATH $mountdir/system

# Full system runs expose console at port 3456. Use telnet or nc on MacOS.
EXPOSE 3456/tcp

# Run the front-end script, by default with the help command.
ENTRYPOINT ["/usr/local/bin/gem5-dev"]
CMD ["help"]
