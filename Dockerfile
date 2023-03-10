
FROM fedora:37

ARG ZOOKEEPER_VERSION=3.8.1
ARG HADOOP_VERSION=3.3.4
ARG ACCUMULO_VERSION=2.1.0

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

RUN dnf update -y && dnf install -y tar && \
    dnf install -y java-latest-openjdk && \
    dnf install -y procps-ng hostname net-tools && \
    dnf install -y which findutils && dnf clean all

# hadoop
ADD hadoop-${HADOOP_VERSION}.tar.gz /usr/local/
RUN ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

# Zookeeper
ADD zookeeper-${ZOOKEEPER_VERSION}.tar.gz /usr/local/
RUN ln -s /usr/local/apache-zookeeper-${ZOOKEEPER_VERSION}-bin /usr/local/zookeeper

# Accumulo
ADD accumulo-${ACCUMULO_VERSION}-bin.tar.gz /usr/local/
RUN ln -s /usr/local/accumulo-${ACCUMULO_VERSION} /usr/local/accumulo
ADD libaccumulo.so /usr/local/accumulo/lib/native/

ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ENV JAVA_HOME /usr/lib/jvm/jre
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD start-process /start-process

CMD /start-accumulo

EXPOSE 9000 50095 42424 9995 9997

