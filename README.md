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
        --link hadoop:hadoop cybermaggedon/accumulo:1.8.0

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
	cybermaggedon/accumulo:1.8.0

```





docker network create --driver=bridge --subnet=10.0.10.0/24 mynet

docker run -p 9000:9000 -v /data/hadoop:/data \
  --ip=10.0.10.5 --net mynet \
  --name hadoop \
  cybermaggedon/hadoop:2.7.3

docker run -p 2181:2181 -v /data/zookeeper:/data \
  --ip=10.0.10.6 --net mynet \
  --link hadoop=hadoop \
  --name zookeeper \
  cybermaggedon/zookeeper:3.4.9

docker run --rm -i -t --ip=10.0.10.10 --net mynet -p 50095:50095 \
  -e ZOOKEEPERS=10.0.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo1 \
  -e MY_HOSTNAME=10.0.10.10 \
  -e GC_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MASTER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e SLAVE_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MONITOR_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e TRACER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e DAEMONS=gc,master,tserver,monitor,tracer \
  -v /data/acc1:/accumulo \
  --link hadoop=hadoop \
  --name acc1 cybermaggedon/accumulo:1.8.0
  
docker run --rm -i -t --ip=10.0.10.11 --net mynet \
  -e ZOOKEEPERS=10.0.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo2 \
  -e MY_HOSTNAME=10.0.10.10 \
  -e GC_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MASTER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e SLAVE_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MONITOR_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e TRACER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e DAEMONS=gc,master,tserver,monitor,tracer \
  -v /data/acc2:/accumulo \
  --link hadoop=hadoop \
  --name acc2 cybermaggedon/accumulo:1.8.0
  
docker run --rm -i -t --ip=10.0.10.12 --net mynet \
  -e ZOOKEEPERS=10.0.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo3 \
  -e MY_HOSTNAME=10.0.10.10 \
  -e GC_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MASTER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e SLAVE_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e MONITOR_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e TRACER_HOSTS=10.0.10.10,10.0.10.11,10.0.10.12 \
  -e DAEMONS=gc,master,tserver,monitor,tracer \
  -v /data/acc3:/accumulo \
  --link hadoop=hadoop \
  --name acc3 cybermaggedon/accumulo:1.8.0

----------------------------------------------------------------------------
