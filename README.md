Accumulo container, needs Hadoop HDFS and Zookeeper.

Simplest scenario, single node Hadoop, single node Zookeeper, single node
Accumulo, no persistence.  Accumulo uses hostname 'hadoop' for HDFS by default,
and 'zookeeper' for Zookeeper.

```

  # Start Hadoop
  docker run --rm --name hadoop cybermaggedon/hadoop:2.7.3

  # Start Zookeeper
  docker run --rm --name zookeeper cybermaggedon/zookeeper:3.4.9

  # Start Accumulo, linking to other containers.
  docker run --rm --name accumulo -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
	--link zookeeper:zookeeper \
        cybermaggedon/accumulo:1.8.0

```

Default Accumulo root password is `accumulo`.  To check it works:

```

  % docker ps | grep accumulo
  % docker exec -it insert-container-ID bash
  # /usr/local/accumulo/bin/accumulo shell -u root -p accumulo
  root@accumulo> tables

```
... and you should see a list of tables.

If you want to persist Accumulo you will need to ensure Hadoop and Zookeeper
are persistent.  Here we are using /data/hadoop and /data/zookeeper as
persistent volumes.

e.g.

```

  # Start Hadoop
  docker run --rm --name hadoop -v /data/hadoop:/data cybermaggedon/hadoop:2.7.3

  # Start Zookeeper
  docker run --rm --name zookeeper -v /data/zookeeper:/data \
        cybermaggedon/zookeeper:3.4.9

  # Start Accumulo, linking to other containers.
  docker run --rm --name accumulo  -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
        --link zookeeper:zookeeper \
	cybermaggedon/accumulo:1.8.0

```

To do anything more complicated, we need to be able to manage the
names or addresses that are provided to containers.  Easiest way
is to set up a user-defined network and allocate the IP addresses manually.

```

  # Create network
  docker network create --driver=bridge --subnet=10.10.0.0/16 my_network

  # HDFS namenode
  docker run --rm --ip=10.10.6.3 --net my_network \
      -e DAEMONS=namenode,datanode,secondarynamenode \
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      cybermaggedon/hadoop:2.7.3

  # HDFS datanodes
  docker run --rm --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      cybermaggedon/hadoop:2.7.3
  docker run --rm --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      cybermaggedon/hadoop:2.7.3

  # Zookeeper cluster, 3 nodes.
  docker run --rm --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.4.9
      
  docker run --rm -i -t --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.4.9
      
  docker run --rm -i -t --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.4.9

  # Accumulo, 3 nodes
  docker run --rm -i -t --ip=10.10.10.10 --net my_network \
      -p 50095:50095 -p 9995:9995 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e INSTANCE_NAME=accumulo01 \
      -e NAMENODE_URI= \
      -e MY_HOSTNAME=10.10.10.10 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      -e DAEMONS=gc,master,tserver,monitor,tracer \
      --link hadoop01:hadoop01 \
      --name acc01 cybermaggedon/accumulo:1.8.0

  docker run --rm -i -t --ip=10.10.10.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e INSTANCE_NAME=accumulo02 \
      -e NAMENODE_URI= \
      -e MY_HOSTNAME=10.10.10.11 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      -e DAEMONS=tserver \
      --link hadoop01:hadoop01 \
      --name acc02 cybermaggedon/accumulo:1.8.0

  docker run --rm -i -t --ip=10.10.10.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e INSTANCE_NAME=accumulo03 \
      -e NAMENODE_URI= \
      -e MY_HOSTNAME=10.10.10.12 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      -e DAEMONS=tserver \
      --link hadoop01:hadoop01 \
      --name acc03 cybermaggedon/accumulo:1.8.0









  
docker run --rm -i -t --ip=10.10.10.11 --net my_network \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=file:/accumulo \
  -e INSTANCE_NAME=accumulo02 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.11 \
  -e GC_HOSTS=10.10.10.10 \
  -e MASTER_HOSTS=10.10.10.10 \
  -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MONITOR_HOSTS=10.10.10.10 \
  -e TRACER_HOSTS=10.10.10.10 \
  -e DAEMONS=tserver \
  -v /data/acc2:/accumulo \
  --link hadoop=hadoop \
  --name acc2 cybermaggedon/accumulo:1.8.0
  
docker run --rm -i -t --ip=10.10.10.12 --net my_network \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=file:/accumulo \
  -e INSTANCE_NAME=accumulo03 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.12 \
  -e GC_HOSTS=10.10.10.10 \
  -e MASTER_HOSTS=10.10.10.10 \
  -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MONITOR_HOSTS=10.10.10.10 \
  -e TRACER_HOSTS=10.10.10.10 \
  -e DAEMONS=tserver \
  -v /data/acc3:/accumulo \
  --link hadoop=hadoop \
  --name acc3 cybermaggedon/accumulo:1.8.0

----------------------------------------------------------------------------

docker run --rm -i -t --ip=10.10.10.10 --net my_network -p 9995:9995 -p 9997:9997 \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo1 \
  -e ACCUMULO_INIT=y \
  -e INSTANCE_NAME=accumulo1 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.10 \
  -e GC_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MASTER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MONITOR_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e TRACER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e DAEMONS=gc,master,tserver,monitor,tracer \
  --link hadoop=hadoop \
  --name acc1 cybermaggedon/accumulo:1.8.0
  
docker run --rm -i -t --ip=10.10.10.11 --net my_network -P \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo1 \
  -e INSTANCE_NAME=accumulo1 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.11 \
  -e GC_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MASTER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MONITOR_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e TRACER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e DAEMONS=tserver,tracer \
  --link hadoop=hadoop \
  --name acc2 cybermaggedon/accumulo:1.8.0
  
docker run --rm -i -t --ip=10.10.10.12 --net my_network -P \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=hdfs://hadoop:9000/accumulo1 \
  -e INSTANCE_NAME=accumulo1 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.12 \
  -e GC_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MASTER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e MONITOR_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e TRACER_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
  -e DAEMONS=tserver,tracer \
  --link hadoop=hadoop \
  --name acc3 cybermaggedon/accumulo:1.8.0

----------------------------------------------------------------------------

docker run --rm -i -t --ip=10.10.10.10 --net my_network -p 9995:9995 -p 9997:9997 \
  -e ZOOKEEPERS=10.10.10.6 \
  -e HDFS_VOLUMES=file:/accumulo \
  -e ACCUMULO_INIT=y \
  -e INSTANCE_NAME=accumulo01 \
  -e NAMENODE_URI= \
  -e MY_HOSTNAME=10.10.10.10 \
  -e GC_HOSTS=10.10.10.10 \
  -e MASTER_HOSTS=10.10.10.10 \
  -e SLAVE_HOSTS=10.10.10.10 \
  -e MONITOR_HOSTS=10.10.1010 \
  -e TRACER_HOSTS=10.10.10.10 \
  -e DAEMONS=gc,master,tserver,monitor,tracer \
  --link hadoop=hadoop \
  --name acc1 cybermaggedon/accumulo:1.8.0

