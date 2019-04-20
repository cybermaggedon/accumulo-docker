
REPOSITORY=cybermaggedon/accumulo
VERSION=$(shell git describe | sed 's/^v//')
ZOOKEEPER_VERSION=3.4.14
HADOOP_VERSION=2.9.2
ACCUMULO_VERSION=1.9.3

SUDO=
BUILD_ARGS=--build-arg ZOOKEEPER_VERSION=${ZOOKEEPER_VERSION} \
  --build-arg HADOOP_VERSION=${HADOOP_VERSION} \
  --build-arg ACCUMULO_VERSION=${ACCUMULO_VERSION}

DOWNLOADS=accumulo-${ACCUMULO_VERSION}-bin.tar.gz \
  zookeeper-${ZOOKEEPER_VERSION}.tar.gz hadoop-${HADOOP_VERSION}.tar.gz

all: ${DOWNLOADS}
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION} .

# FIXME: May not be the right mirror for you.
zookeeper-${ZOOKEEPER_VERSION}.tar.gz:
	wget -q -O $@ http://www.mirrorservice.org/sites/ftp.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz

# FIXME: May not be the right mirror for you.
accumulo-${ACCUMULO_VERSION}-bin.tar.gz:
	wget -q -O $@ mirrors.ukfast.co.uk/sites/ftp.apache.org/accumulo/${ACCUMULO_VERSION}/accumulo-${ACCUMULO_VERSION}-bin.tar.gz

# FIXME: May not be the right mirror for you.
hadoop-${HADOOP_VERSION}.tar.gz:
	wget -q -O $@ http://mirror.catn.com/pub/apache/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

push:
	${SUDO} docker push ${REPOSITORY}:${VERSION}

# Continuous deployment support
BRANCH=master
FILE=accumulo-version
REPO=git@github.com:cybermaggedon/gaffer-docker

tools: phony
	if [ ! -d tools ]; then \
		git clone git@github.com:trustnetworks/cd-tools tools; \
	fi; \
	(cd tools; git pull)

phony:

bump-version: tools
	tools/bump-version

update-cluster-config: tools
	tools/update-version-file ${BRANCH} ${VERSION} ${FILE} ${REPO}

