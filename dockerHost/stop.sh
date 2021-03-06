#!/bin/bash

if [ -z $1 ]; then
	echo Provide image name
	exit 1
fi

# stop existing container
container=$(sudo docker ps | grep $1 | cut -f1 -d' ')
if [ ! -z ${container} ]; then
   sudo docker stop ${container}
fi

