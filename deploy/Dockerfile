FROM ubuntu:trusty

# update and install java
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends openjdk-7-jre-headless

ADD ./embedmongo /root/.embedmongo/linux
ADD ./target /opt/app

EXPOSE 9000

WORKDIR /opt/app/

ENTRYPOINT ["bin/cameoserver"]

CMD ["-Dconfig.file=conf/secret.conf","-Dfile.encoding=UTF-8"]
