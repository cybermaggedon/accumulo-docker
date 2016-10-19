
FROM fedora:24

MAINTAINER cybermaggedon

RUN echo -e "\n* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf

RUN dnf install -y tar

COPY accumulo-1.8.0-bin.tar.gz /usr/local/accumulo.tgz
RUN cd /usr/local/ && tar xvfz accumulo.tgz
RUN mv /usr/local/accumulo-1.8.0 /usr/local/accumulo
ENV ACCUMULO_HOME /usr/local/accumulo
ENV PATH $PATH:$ACCUMULO_HOME/bin
ADD accumulo/* $ACCUMULO_HOME/conf/

ADD start-accumulo /start-accumulo
ADD stop-accumulo /stop-accumulo

RUN chown root:root /*-accumulo; chmod 700 /*-accumulo

CMD /start-accumulo

EXPOSE 9000 50095 42424

