#!/bin/bash
set -e

# constants
updateWww=false
wwwImage="cameowww"
wwwPort=9001
appPort=9000

# arguments
for i in "$@" ; do
	case $i in
	    --app-image=*)			
		    appImage="${i#*=}"
	    ;;
	    --registry=*)
			registry="${i#*=}"	
	    ;;
	    --update-www)	
			updateWww=true
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

#update www
if [ "${updateWww}" == true ]; then
	echo "Updating www image"
	stopContainer ${wwwImage}	
	name=${registry}/${wwwImage}
	sudo docker pull ${name}
	sudo docker run -p ${wwwPort}:9000 -d ${name}
fi

#update app
if [ ! -z "${appImage}" ]; then
	echo "Updating app image"
	stopContainer ${appImage}	
	name=${registry}/${appImage}
	sudo docker pull ${name}
	sudo docker run -p ${appPort}:9000 -d ${name}
fi
