#!/bin/bash
imageName="cameo-test"
imagePort=9000
embedMongoFile="/opt/mongodb-linux-x86_64-2.6.3.tgz"

if [ ! -z "$1" ]; then
	imagePort=$1
fi	

echo -e "\e[33m[ CameoTest - Running tests on port: ${imagePort} ]\033[0m"

if[ -e $embedMongoFile ];then 
	mkdir -p embedmongo
	cp -v $embedMongoFile embedmongo/
fi

./createDockerImage.sh ${imageName}
sudo docker run -p ${imagePort}:9000 -d ${imageName}

containerId=$(sudo docker ps | grep ${imageName} | cut -f1 -d' ')

timeout=50
while [ -z "${log}" ] && [ "$timeout" -gt 0 ]; do
	echo waiting for container to start. Patience left: ${timeout}
	log=$(sudo docker logs ${containerId} | grep Listening)
	sleep 2	
	timeout=`expr $timeout - 1` 
done

cd cameoJSClient
./test.sh test http://localhost:${imagePort}/m/ http://localhost:${imagePort}/a/v1 

echo -e "\e[33m[ CameoTest - Stopping test container ]\033[0m"
sudo docker stop ${containerId}
echo -e "\e[33m[ CameoTest - Removing test container ]\033[0m"
sudo docker rm ${containerId}


