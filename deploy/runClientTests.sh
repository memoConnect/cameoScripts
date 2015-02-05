#!/bin/bash
imageName="cameo-test"
imagePort=9000
embedMongoFile="/opt/mongodb-linux-x86_64-2.6.*"

#handle arguments
for i in "$@" ; do
	case $i in
	    --imagePort=*)			
		    imagePort="${i#*=}"
	    ;;
	    --specs=*)	
	    	imageName="cameo-test-custom"		
		    specs="${i#*=}"
			echo -e "\e[33m[ CameoTest - Running with custom specs: $2 ]\033[0m"
		;;
	    --screenshotPath=*)			
		    screenshotPath="${i#*=}"
	    ;;
	esac
done

echo -e "\e[33m[ CameoTest - Running tests on port: ${imagePort} ]\033[0m"

mkdir -p embedmongo
cp -v $embedMongoFile embedmongo/

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
./test.sh --target=test --wwwUrl=http://localhost:${imagePort}/m/ --apiUrl=http://localhost:${imagePort}/a/ --specs="$2" --screenshotPath=${screenshotPath}

exitStatus=$?

echo -e "\e[33m[ CameoTest - Stopping test container ]\033[0m"
sudo docker stop ${containerId}
echo -e "\e[33m[ CameoTest - Removing test container ]\033[0m"
sudo docker rm ${containerId}

exit $exitStatus