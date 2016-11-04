
FROM fedora:24

MAINTAINER cybermaggedon

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

RUN dnf install -y tar
RUN dnf install -y java-1.8.0-openjdk
RUN dnf install -y procps-ng hostname
RUN dnf install -y which

# hadoop
ADD hadoop-2.7.3.tar.gz /usr/local/
RUN ln -s /usr/local/hadoop-2.7.3 /usr/local/hadoop

# Zookeeper
ADD zookeeper-3.4.9.tar.gz /usr/local/
RUN ln -s /usr/local/zookeeper-3.4.9 /usr/local/zookeeper

# Accumulo
ADD accumulo-1.7.2-bin.tar.gz /usr/local/
RUN ln -s /usr/local/accumulo-1.7.2 /usr/local/accumulo

# Diagnostic tools :/
RUN dnf install -y net-tools
RUN dnf install -y telnet

ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD stop-accumulo /stop-accumulo

CMD /start-accumulo

EXPOSE 9000 50095 42424 9995 9997

