This work is based on [https://github.com/medined/docker-accumulo](https://github.com/medined/docker-accumulo), and mraad/accumulo.

Single-node Accumulo instance for development purposes.  There are two
hard-coded hostnames: 'hadoop' for HDFS, and 'zookeeper' for
Zookeeper.

To run:

```

  # Start Hadoop
  docker run --rm --name hadoop cybermaggedon/hadoop:2.7.3

  # Start Zookeeper
  docker run --rm --name zookeeper cybermaggedon/zookeeper:3.4.9

  # Start Accumulo, linking to other containers.
  docker run --rm --name accumulo --link zookeeper:zookeeper \
        --link hadoop:hadoop cybermaggedon/accumulo:1.7.8

```

Default root password is `accumulo`.

To check it works:

```

  % docker ps | grep accumulo
  % docker exec -it insert-container-ID bash
  # /usr/local/accumulo/bin/accumulo shell -u root -p accumulo
  root@accumulo> tables

```
... and you should see a list of tables.

If you want to persist Accumulo you will need to ensure Hadoop and Zookeeper
are persistent, and mount a volume on ```/accumulo```.

e.g.

```

  # Start Hadoop
  docker run --rm --name hadoop -v /data/hadoop:/data cybermaggedon/hadoop:2.7.3

  # Start Zookeeper
  docker run --rm --name zookeeper -v /data/zookeeper:/data \
        cybermaggedon/zookeeper:3.4.9

  # Start Accumulo, linking to other containers.
  docker run --rm --name accumulo --link zookeeper:zookeeper \
        --link hadoop:hadoop -v /data/accumulo:/accumulo \
	cybermaggedon/accumulo:1.7.8

```
