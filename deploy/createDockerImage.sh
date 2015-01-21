#!/bin/bash

if [ -z $1 ]; then
	echo image name required
fi

# copy to subfolder to decrease context
rm -rf docker
mkdir docker
cp -r target Dockerfile embedmongo docker/

cd docker
sudo docker build -t ${1} --rm .

if [ "$2" == "push" ]; then
	echo "Pushing to: "${1} 
	sudo docker push --insecure-registry ${1}
fi	
