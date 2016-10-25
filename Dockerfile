
FROM fedora:24

MAINTAINER cybermaggedon

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

RUN dnf install -y tar
RUN dnf install -y java-1.8.0-openjdk
RUN dnf install -y procps-ng hostname

# hadoop
COPY hadoop-2.7.3.tar.gz /usr/local/hadoop.tgz
RUN cd /usr/local && tar xfz /usr/local/hadoop.tgz
RUN mv /usr/local/hadoop-2.7.3 /usr/local/hadoop
RUN rm -f /usr/local/hadoop.tgz

# Zookeeper
COPY zookeeper-3.4.9.tar.gz /usr/local/zookeeper.tgz
RUN cd /usr/local/ && tar xvfz zookeeper.tgz
RUN mv /usr/local/zookeeper-3.4.9 /usr/local/zookeeper
RUN rm -f /usr/local/zookeeper.tgz

COPY accumulo-1.8.0-bin.tar.gz /usr/local/accumulo.tgz
RUN cd /usr/local/ && tar xvfz accumulo.tgz
RUN mv /usr/local/accumulo-1.8.0 /usr/local/accumulo
RUN rm -f /usr/local/accumulo.tgz

ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD stop-accumulo /stop-accumulo

RUN chown root:root /*-accumulo; chmod 700 /*-accumulo

CMD /start-accumulo

EXPOSE 9000 50095 42424

