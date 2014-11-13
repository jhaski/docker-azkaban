FROM ubuntu:14.04

RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list
RUN	echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update

#Prevent daemon start during install
RUN	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && mkdir /var/run/sshd && echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y less ntp net-tools inetutils-ping curl git unzip telnet

#MySQL
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server && \
    sed -i -e "s|127.0.0.1|0.0.0.0|g" -e "s|max_allowed_packet.*|max_allowed_packet = 1024M|" /etc/mysql/my.cnf

#Install Oracle Java 7
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-software-properties && \
    add-apt-repository ppa:webupd8team/java -y && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y oracle-java7-installer

#Azkaban Web Server
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.1/azkaban-web-server-2.1.tar.gz && \
    tar xf azkaban-web-server-*.tar.gz && \
    rm azkaban-web-server-*.tar.gz

#Azkaban Executor Server
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.1/azkaban-executor-server-2.1.tar.gz && \
    tar xf azkaban-executor-server-*.tar.gz && \
    rm azkaban-executor-server-*.tar.gz

#Azkaban MySQL scripts
RUN wget https://s3.amazonaws.com/azkaban2/azkaban2/2.1/azkaban-sql-script-2.1.tar.gz && \
    tar xf azkaban-sql-script-*.tar.gz && \
    rm azkaban-sql-script-*.tar.gz

#MySQL JDBC driver
RUN wget -O /azkaban-2.1/extlib/mysql-connector-java-5.1.26.jar http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/5.1.26/mysql-connector-java-5.1.26.jar

#Configure
RUN mkdir /tmp/web && sed -i -e "s|^tmpdir=|tmpdir=/tmp/web|" -e "s|&||" /azkaban-2.1/bin/azkaban-web-start.sh && \
    mkdir /tmp/executor && sed -i -e "s|^tmpdir=|tmpdir=/tmp/executor|" -e "s|&||" /azkaban-2.1/bin/azkaban-executor-start.sh && \
    cd azkaban-2.1 && \
    keytool -keystore keystore -alias jetty -genkey -keyalg RSA -keypass password -storepass password -dname "CN=Unknown, OU=Unknown, O=Unknown,L=Unknown, ST=Unknown, C=Unknown"

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Init MySql
ADD mysql.ddl mysql.ddl
RUN mysqld & sleep 3 && \
    mysql < mysql.ddl && \
    mysql --database=azkaban2 < /azkaban-2.1/create-all-sql-2.1.sql && \
    mysqladmin shutdown

EXPOSE 22 8443

