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
	domain=$(echo ${1} | cut -d'/' -f1) 
	echo "Pushing to: "${1}
	echo "Domain: "${domain}
	sudo docker --insecure-registry ${domain} push ${1}
fi	
