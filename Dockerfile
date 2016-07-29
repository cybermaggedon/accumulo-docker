FROM hadoop

MAINTAINER bunchy

ENV PATH $PATH:$HADOOP_PREFIX/bin

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

ADD zookeeper-3.4.8.tar.gz /usr/local
RUN ln -s /usr/local/zookeeper-3.4.8 /usr/local/zookeeper;\
 chown -R root:root /usr/local/zookeeper-3.4.8;\
 mkdir -p /var/zookeeper
ENV ZOOKEEPER_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOOKEEPER_HOME/bin
ADD zookeeper/* $ZOOKEEPER_HOME/conf/

ADD accumulo-1.7.2-bin.tar.gz /usr/local
RUN ln -s /usr/local/accumulo-1.7.2 /usr/local/accumulo;\
 chown -R root:root /usr/local/accumulo-1.7.2
ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-all.sh /start-accumulo
ADD stop-all.sh /stop-accumulo

RUN chown root:root /*-accumulo;\
 chmod 700 /*-accumulo

ADD init-accumulo.sh /tmp/
RUN /tmp/init-accumulo.sh

EXPOSE 2181 9000 50095

