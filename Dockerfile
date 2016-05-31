# Dockerfile for Apache Marmotta

FROM debian:jessie-backports
MAINTAINER Bruno Thiao-Layel <bruno.thiaolayel@isped.u-bordeaux2.fr>

EXPOSE 8080

WORKDIR /marmotta-webapp
ADD . /marmotta-webapp

# configuration
ENV DEBIAN_FRONTEND noninteractive
ENV DB_NAME marmotta
ENV DB_USER marmotta
ENV DB_PASS s3cr3t
ENV PG_VERSION 9.4
ENV WAR_PATH target/marmotta.war
ENV CONF_PATH /var/lib/marmotta/system-config.properties

ENV JAVA_OPTS="-Xmx6G -XX:PermSize=1024m -XX:MaxPermSize=512m"

# test build
RUN test -e $WAR_PATH || exit

# prepare the environment
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
		openjdk-8-jdk \
        tomcat7 \
    || apt-get install -y -f

# install and configure postgres from the PGDG repo
RUN apt-get update && apt-get install -y locales apt-utils \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
#RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
#RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > /etc/apt/sources.list.d/pgdg.list
#RUN apt-get update \
#	&& apt-get install -y postgresql-common \
#	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
#	&& apt-get install -y \
#		postgresql-$PG_VERSION \
#		postgresql-contrib-$PG_VERSION
#RUN pg_createcluster $PG_VERSION main --start
#USER postgres
#RUN service postgresql start \
#    && psql --command "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" \
#    && psql --command "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;"
#USER root
#RUN service postgresql stop
#RUN echo "host all  all    127.0.0.1/32  md5" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf
#RUN echo "listen_addresses='*'" >> /etc/postgresql/$PG_VERSION/main/postgresql.conf

## base requirements
#RUN apt-get update \
#	&& apt-get install -y \
#		openjdk-7-jre-headless \
#		tomcat7
RUN service tomcat7 stop

# package from source code and install the webapp
#RUN dpkg --debug=2000 --install target/marmotta_*_all.deb <-- we'd need to fix the postinst
RUN mkdir -p /usr/share/marmotta
RUN cp $WAR_PATH /usr/share/marmotta/
RUN chown tomcat7:tomcat7 /usr/share/marmotta/marmotta.war
RUN cp src/deb/tomcat/marmotta.xml /var/lib/tomcat7/conf/Catalina/localhost/
RUN chown tomcat7:tomcat7 /var/lib/tomcat7/conf/Catalina/localhost/marmotta.xml
RUN mkdir -p "$(dirname $CONF_PATH)"
RUN echo "security.enabled = false" > $CONF_PATH
RUN echo "database.type = postgres" >> $CONF_PATH
RUN echo "database.url = jdbc:postgresql://localhost:5432/$DB_NAME?prepareThreshold=3" >> $CONF_PATH
RUN echo "database.user = $DB_USER" >> $CONF_PATH
RUN echo "database.password = $DB_PASS" >> $CONF_PATH
RUN chown -R tomcat7:tomcat7 "$(dirname $CONF_PATH)"

# cleanup
##RUN mvn clean
#RUN apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# cleanup
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/marmotta-webapp/src/docker/entrypoint.sh"]

# how to run it :
#sudo docker build -t bthiaola/marmotta-6g
#sudo docker run -d -p 8080:8080 --name marmotta bthiaola/marmotta-6g
