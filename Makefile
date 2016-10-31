
REPOSITORY=cybermaggedon/accumulo
VERSION=1.7.2

SUDO=
BUILD_ARGS=

all: accumulo-1.7.2-bin.tar.gz zookeeper-3.4.9.tar.gz hadoop-2.7.3.tar.gz
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION} .

# FIXME: May not be the right mirror for you.
zookeeper-3.4.9.tar.gz:
	wget http://www.mirrorservice.org/sites/ftp.apache.org/zookeeper/zookeeper-3.4.9/zookeeper-3.4.9.tar.gz

# FIXME: May not be the right mirror for you.
accumulo-1.7.2-bin.tar.gz:
	wget mirrors.ukfast.co.uk/sites/ftp.apache.org/accumulo/1.7.2/accumulo-1.7.2-bin.tar.gz

# FIXME: May not be the right mirror for you.
hadoop-2.7.3.tar.gz:
	wget http://mirror.catn.com/pub/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz

push:
	${SUDO} docker push ${REPOSITORY}:${VERSION}

