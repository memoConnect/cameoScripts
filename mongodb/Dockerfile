FROM ubuntu:trusty
# update and install mongodb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y -q mongodb-org

# add config and keyfile
RUN mkdir -p /private/var/
ADD ./mongo_keyfile.pem  /private/var/mongo_keyfile.pem
ADD ./mongod.conf /etc/mongod.conf

ENTRYPOINT ["/usr/bin/mongod","-f","/etc/mongod.conf"]
