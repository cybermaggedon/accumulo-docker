
FROM fedora:29

ARG ZOOKEEPER_VERSION=3.4.10
ARG HADOOP_VERSION=2.8.1
ARG ACCUMULO_VERSION=1.8.1

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

RUN dnf update -y && dnf install -y tar && \
    dnf install -y java-1.8.0-openjdk && dnf install -y procps-ng hostname && \
    dnf install -y which findutils && dnf clean all

# hadoop
ADD hadoop-${HADOOP_VERSION}.tar.gz /usr/local/
RUN ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

# Zookeeper
ADD zookeeper-${ZOOKEEPER_VERSION}.tar.gz /usr/local/
RUN ln -s /usr/local/zookeeper-${ZOOKEEPER_VERSION} /usr/local/zookeeper

# Accumulo
ADD accumulo-${ACCUMULO_VERSION}-bin.tar.gz /usr/local/
RUN ln -s /usr/local/accumulo-${ACCUMULO_VERSION} /usr/local/accumulo

# Diagnostic tools :/
RUN dnf install -y net-tools
RUN dnf install -y telnet

ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD start-process /start-process

CMD /start-accumulo

EXPOSE 9000 50095 42424 9995 9997

