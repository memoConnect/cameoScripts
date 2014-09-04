#!/bin/bash
set -e

# constants
updateWww=false
wwwImage="cameowww"
port=9000

# arguments
for i in "$@" ; do
	case $i in
	    --app-image=*)			
		    appImage="${i#*=}"
	    ;;
	    --registry=*)
			registry="${i#*=}"	
	    ;;
	    --port=*)
			port="${i#*=}"
	    ;;
	    *)
	      echo Unkown option: ${i}
	      exit 1
	    ;;
	esac
done

if [ -z $registry ]; then
	echo No registry
	exit 1
fi

# helper functions
function stopContainer {
	echo "stoping container" $1
	containerId=$(sudo docker ps | grep $1 | cut -f1 -d' ')
	if [ ! -z ${containerId} ]; then
	   sudo docker stop ${containerId}
	fi
}

#update app
if [ ! -z "${appImage}" ]; then
	echo "Updating app image"
	stopContainer ${appImage}	
	name=${registry}/${appImage}
	sudo docker pull ${name}
	sudo docker run -p ${port}:9000 -d ${name}
	# cleanup unused containers and images
	containers=$(sudo docker ps -a | grep Exited | tr -s ' ' | cut -d' ' -f1)
	if [ -n "$containers" ]; then
		sudo docker rm $containers
	fi
	images=$(sudo docker images | grep "^<none>" | tr -s ' ' | cut -d' ' -f3)
	if [ -n "$images" ]; then
		sudo docker rmi $images
	fi

fi
