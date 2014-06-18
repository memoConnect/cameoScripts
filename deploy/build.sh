#!/bin/bash
set -e

# default buildmode ist test
buildMode=test
buildApps=false
apiPort=9000

#handle arguments
for i in "$@" ; do
	case $i in
	    -m=*|--mode=*)			
		    buildMode="${i#*=}"
	    ;;
	    -latestServer|--latestServer)
	    	latestServer=true
	    ;;
	    -latestClient|--latestClient)
	    	latestClient=true
	    ;;	
	    -p=*|--port*)
		    apiPort="${i#*=}"
		;;
		-a|--build-apps)
			buildApps=true
		;;
	    *)
	      echo Unkown option: ${i}
	      exit 1
	    ;;
	esac
done


# define repositories
serverGit=https://github.com/memoConnect/cameoServer.git
clientGit=https://github.com/memoConnect/cameoJSClient.git

# get location of script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${dir}

# get current version
if [ -s ./version ]; then
	version=$(cat ./version)
else
	version="no version"
fi

echo -e "\e[33m[ CameoBuild - Build mode: ${buildMode}, Version: ${version} ]\033[0m"

serverDir=${dir}/$(echo ${serverGit} | rev | cut -d"/" -f1 | rev | cut -d"." -f1)
clientDir=${dir}/$(echo ${clientGit} | rev | cut -d"/" -f1 | rev | cut -d"." -f1) 
secretDir=${dir}/cameoSecrets

echo -e "\e[33m[ CameoBuild - Updating repositories ]\033[0m"

# clone repos if dirs dont exist
export GIT_SSL_NO_VERIFY=true
if [ ! -d "${serverDir}" ]; then
	git clone ${serverGit}
fi

if [ ! -d "${clientDir}" ]; then
	git clone ${clientGit}
fi

if [ ! -d "${secretDir}" ]; then
	echo No cameoSecrets found in dir: ${secretDir}
	exit 1
fi

quickCompile=false
copyFixtures=false
currentBuild=""

# helper function to get latest tag
function checkoutLatestTag {
	git fetch 
	git fetch --tags
	tag=$(git for-each-ref --format="%(refname)" --sort=-taggerdate refs/tags | grep -i $1 | head -n1)
	git checkout ${tag}
	currentBuild=$(echo ${tag} | cut -d'_' -f2)
}

case "${buildMode}" in 
	"test")
		quickCompile=true
		copyFixtures=true

		secretFile="secret_local.conf"
	
		apiUrlArg="--apiUrl=http://localhost:${apiPort}/a/v1"

		cd ${serverDir}
		if [ "${latestServer}" == true ]; then
			git checkout dev
			git pull
			serverVersion=${version}_"dev"
		else
			checkoutLatestTag "build_" 
			serverVersion=${version}.${currentBuild}			
		fi

		cd ${clientDir}
		if [ "${latestClient}" == true ]; then
			git checkout dev
			git pull
			clientVersion=${version}_"dev"
		else
			checkoutLatestTag "build_" 
			clientVersion=${version}.${currentBuild}	
		fi	
		;;

	"stagetest")
		copyFixtures=true

		secretFile="secret_local.conf"
	
		apiUrlArg="--apiUrl=http://localhost:${apiPort}/a/v1"

		cd ${serverDir} 
		git fetch 
		git fetch --tags
		git checkout tags/stage
		serverVersion=${version}_"stage"

		cd ${clientDir}
		git fetch 
		git fetch --tags
		git checkout tags/stage
		clientVersion=${version}_"stage"
		;;

	"dev")
		quickCompile=true
		secretFile="secret_dev.conf"
		
		cd ${serverDir}
		checkoutLatestTag "build_" 
		serverVersion=${version}.${currentBuild}			

		cd ${clientDir}
		checkoutLatestTag "build_" 
		clientVersion=${version}.${currentBuild}	
		;;

	"stage")
		secretFile="secret_stage.conf"

		cd ${serverDir}
		checkoutLatestTag "stage_" 
		serverVersion=${version}.${currentBuild}

		cd ${clientDir}
		checkoutLatestTag "stage_" 
		clientVersion=${version}.${currentBuild}
		;;
		
	"prod")
		secretFile="secret_prod.conf"

		cd ${serverDir}
		git checkout master
		git pull

		cd ${clientDir}
		git checkout master
		git pull
		;;

	*)
		echo Invalid mode: ${buildMode}
		exit 1
		;;
esac

# build client	
cd ${clientDir}
if [ "${buildApps}" == true ]; then
	echo -e "\e[33m[ CameoBuild - Building client with mobile apps, mode: ${buildMode}, version: ${clientVersion} ]\033[0m"
	./compile.sh --mode=${buildMode} ${apiUrlArg} --version=${clientVersion} --phonegap 
else
	echo -e "\e[33m[ CameoBuild - Building client, mode: ${buildMode}, version: ${clientVersion} ]\033[0m"
	./compile.sh --mode=${buildMode} ${apiUrlArg} --version=${clientVersion} 
fi

# remove old client stuff
rm -rf ${serverDir}/public
# copy compiled client to public dir of server
mkdir -p ${serverDir}/public
cp -r ${clientDir}/dist/* ${serverDir}/public/

# build server
echo -e "\e[33m[ CameoBuild - Building server, version: ${serverVersion}, quickCompile: ${quickCompile} ]\033[0m"
cd ${serverDir}
if [ "${quickCompile}" == true ]; then
	./compile.sh ${serverVersion} quick
else
	./compile.sh ${serverVersion}
fi	 

# remove old target
echo -e "\e[33m[ CameoBuild - Create target ]\033[0m"
rm -fr ${dir}/target

# copy new target
cp -r ${serverDir}/target/universal/stage ${dir}/target

# copy fixtures
if [ "${copyFixtures}" == true ]; then
	echo -e "\e[33m[ CameoBuild - Copying fixtures ]\033[0m"
	cp -r ${serverDir}/fixtures ${dir}/target
fi	

# copy secret
cp ${secretDir}/${secretFile} ${dir}/target/conf/secret.conf
