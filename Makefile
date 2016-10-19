
REPOSITORY=cybermaggedon/accumulo
VERSION=2.7.3

SUDO=
BUILD_ARGS=

all: accumulo-1.8.0-bin.tar.gz
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION} .

# FIXME: May not be the right mirror for you.
accumulo-1.8.0-bin.tar.gz:
	wget mirrors.ukfast.co.uk/sites/ftp.apache.org/accumulo/1.8.0/accumulo-1.8.0-bin.tar.gz

push:
	${SUDO} docker build ${BUILD_ARGS} -t ${REPOSITORY}:${VERSION}	

