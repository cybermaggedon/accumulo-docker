
REPOSITORY=cybermaggedon/accumulo
VERSION=$(shell git describe | sed 's/^v//')
ZOOKEEPER_VERSION=3.4.14
HADOOP_VERSION=3.2.0
ACCUMULO_VERSION=2.0.0-alpha-2

SUDO=
BUILD_ARGS=--build-arg ZOOKEEPER_VERSION=${ZOOKEEPER_VERSION} \
  --build-arg HADOOP_VERSION=${HADOOP_VERSION} \
  --build-arg ACCUMULO_VERSION=${ACCUMULO_VERSION}

DOWNLOADS=accumulo-${ACCUMULO_VERSION}-bin.tar.gz \
  zookeeper-${ZOOKEEPER_VERSION}.tar.gz hadoop-${HADOOP_VERSION}.tar.gz

all: ${DOWNLOADS} container

NATIVE_LIB=libaccumulo.so

container: ${NATIVE_LIB}
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION} .

${NATIVE_LIB}:
	-rm -rf accumulo-${ACCUMULO_VERSION}
	tar xfz accumulo-${ACCUMULO_VERSION}-bin.tar.gz
	(cd accumulo-${ACCUMULO_VERSION}; bin/accumulo-util build-native)
	mv accumulo-${ACCUMULO_VERSION}/lib/native/libaccumulo.so .
	rm -rf accumulo-${ACCUMULO_VERSION}

# FIXME: May not be the right mirror for you.
zookeeper-${ZOOKEEPER_VERSION}.tar.gz:
	wget -O $@ http://apache.mirror.anlx.net/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz

# FIXME: May not be the right mirror for you.
accumulo-${ACCUMULO_VERSION}-bin.tar.gz:
	wget -O $@ https://apache.mirrors.nublue.co.uk/accumulo/${ACCUMULO_VERSION}/accumulo-${ACCUMULO_VERSION}-bin.tar.gz

# FIXME: May not be the right mirror for you.
hadoop-${HADOOP_VERSION}.tar.gz:
	wget -O $@ http://www.mirrorservice.org/sites/ftp.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

push:
	${SUDO} docker push ${REPOSITORY}:${VERSION}

