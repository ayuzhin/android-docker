#!/bin/sh
# removing old alias
docker rm droidlibsdocker
# build image
docker build . -t droidlibs_docker
# point droidlibsdocker to the latest version
docker run -d --name droidlibsdocker droidlibs_docker:latest
# copy results out of the container
docker cp droidlibsdocker:/home/user/libs.zip .