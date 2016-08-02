
FROM cybermaggedon/hadoop

MAINTAINER cybermaggedon

ENV PATH $PATH:$HADOOP_PREFIX/bin

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

ADD zookeeper-3.4.8.tar.gz /usr/local
RUN ln -s /usr/local/zookeeper-3.4.8 /usr/local/zookeeper
RUN mkdir -p /data/zookeeper
ENV ZOOKEEPER_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOOKEEPER_HOME/bin
ADD zookeeper/* $ZOOKEEPER_HOME/conf/

ADD accumulo-1.7.2-bin.tar.gz /usr/local
RUN ln -s /usr/local/accumulo-1.7.2 /usr/local/accumulo
ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD stop-accumulo /stop-accumulo

RUN chown root:root /*-accumulo; chmod 700 /*-accumulo

CMD /start-accumulo; while true; do sleep 10000; done

EXPOSE 2181 9000 50095 42424

