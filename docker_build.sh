#!/bin/sh
# removing old alias
docker rm droidlibsdocker
# build image
if [ -z "$1" ] ; then
    docker build . -t droidlibs_docker -m 6g
else
    docker build . -t droidlibs_docker -m 6g --build-arg BUILD_CONFIG=$1
fi
# point droidlibsdocker to the latest version
docker run -d --name droidlibsdocker -m 6g droidlibs_docker:latest
# copy results out of the container
docker cp droidlibsdocker:/home/user/libs.zip .