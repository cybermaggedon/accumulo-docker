Accumulo container, needs Hadoop HDFS and Zookeeper.

Simplest scenario, single node Hadoop, single node Zookeeper, single node
Accumulo, no persistence.  Accumulo uses hostname 'hadoop' for HDFS by default,
and 'zookeeper' for Zookeeper.

```
  # Start Hadoop
  docker run -d --name hadoop cybermaggedon/hadoop:2.8.0

  # Start Zookeeper
  docker run -d --name zookeeper cybermaggedon/zookeeper:3.4.10

  # Start Accumulo, linking to other containers.
  docker run -d --name accumulo -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
	--link zookeeper:zookeeper \
        cybermaggedon/accumulo:1.8.1

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
  docker run -d --name hadoop -v /data/hadoop:/data cybermaggedon/hadoop:2.8.0

  # Start Zookeeper
  docker run -d --name zookeeper -v /data/zookeeper:/data \
        cybermaggedon/zookeeper:3.4.10

  # Start Accumulo, linking to other containers.
  docker run -d --name accumulo  -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
        --link zookeeper:zookeeper \
	cybermaggedon/accumulo:1.8.1

```

To do anything more complicated, we need to be able to manage the
names or addresses that are provided to containers.  Easiest way
is to set up a user-defined network and allocate the IP addresses manually.

```
  ############################################################################
  # Create network
  ############################################################################
  docker network create --driver=bridge --subnet=10.10.0.0/16 my_network

  ############################################################################
  # HDFS
  ############################################################################

  # Namenode
  docker run -d --ip=10.10.6.3 --net my_network \
      -e DAEMONS=namenode,datanode,secondarynamenode \
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      cybermaggedon/hadoop:2.8.0

  # Datanodes
  docker run -d --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      cybermaggedon/hadoop:2.8.0

  docker run -d --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      cybermaggedon/hadoop:2.8.0

  ############################################################################
  # Zookeeper cluster, 3 nodes.
  ############################################################################
  docker run -d --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.4.10
      
  docker run -d --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.4.10
      
  docker run -d --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.4.10

  ############################################################################
  # Accumulo, 3 nodes
  ############################################################################
  docker run -d --ip=10.10.10.10 --net my_network \
      -p 50095:50095 -p 9995:9995 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.10 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc01 cybermaggedon/accumulo:1.8.1

  docker run -d --ip=10.10.10.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.11 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc02 cybermaggedon/accumulo:1.8.1

  docker run -d --ip=10.10.10.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.12 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc03 cybermaggedon/accumulo:1.8.1

```

If you want persistence, Hadoop and Zookeeper need a volume.  Accumulo uses
HDFS for state, so no volumes needed.

```
  ############################################################################
  # Create network
  ############################################################################
  docker network create --driver=bridge --subnet=10.10.0.0/16 my_network

  ############################################################################
  # HDFS
  ############################################################################

  # Namenode
  docker run -d --ip=10.10.6.3 --net my_network \
      -e DAEMONS=namenode,datanode,secondarynamenode \
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      -v /data/hadoop01:/data \
      cybermaggedon/hadoop:2.8.0

  # Datanodes
  docker run -d --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      -v /data/hadoop02:/data \
      cybermaggedon/hadoop:2.8.0

  docker run -d --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e DAEMONS=datanode -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      -v /data/hadoop03:/data \
      cybermaggedon/hadoop:2.8.0

  ############################################################################
  # Zookeeper cluster, 3 nodes.
  ############################################################################
  docker run -d --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      -v /data/zk1:/data \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.4.10
      
  docker run -d --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      -v /data/zk2:/data \
      cybermaggedon/zookeeper:3.4.10
      
  docker run -d --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      -v /data/zk3:/data \
      cybermaggedon/zookeeper:3.4.10

  ############################################################################
  # Accumulo, 3 nodes
  ############################################################################

  # First node is master, monitor, gc, tracer, tablet server
  docker run -d --ip=10.10.10.10 --net my_network \
      -p 50095:50095 -p 9995:9995 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.10 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc01 cybermaggedon/accumulo:1.8.1

  # Two slave nodes, tablet server only
  docker run -d --ip=10.10.10.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.11 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc02 cybermaggedon/accumulo:1.8.1

  docker run -d --ip=10.10.10.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.12 \
      -e GC_HOSTS=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e SLAVE_HOSTS=10.10.10.10,10.10.10.11,10.10.10.12 \
      -e MONITOR_HOSTS=10.10.10.10 \
      -e TRACER_HOSTS=10.10.10.10 \
      --link hadoop01:hadoop01 \
      --name acc03 cybermaggedon/accumulo:1.8.1

```

The following environment variables are used to tailor the Accumulo
deployment:
- ```ZOOKEEPERS```: A comma separated list of hostnames or IP addresses of
  the Zookeeper servers.  Defaults to ```zookeeper```, useful for
  a single stand-alone Zookeeper.
- ```HDFS_VOLUMES```: A comma separated list of HDFS URIs for volumes to
  store Accumulo data.  I've only tested with one volume.  Defaults
  to ```hdfs://hadoop:9000/accumulo```.
- ```NAMENODE_URI```: The URI of the Hadoop name-node.
  Defaults to ```hdfs://hadoop:9000/accumulo```.
- ```INSTANCE_NAME```: A unique name for this Accumulo instance.  Defaults
  to ```accumulo```.
- ```MY_HOSTNAME```: Hostname or IP address to share with other nodes in
  the cluster.  Defaults to ```localhost```, useful only for a standalone
  cluster.
- ```GC_HOSTS```, ```MASTER_HOSTS```, ```SLAVE_HOSTS```, ```MONITOR_HOSTS```
  and ```TRACER_HOSTS``` list of hostnames or IP addresses of nodes which
  run these daemons.  Defaults to something useful for a single-node cluster.

The following environment variables are used to tailor Accumulo sizing.
The default values are very low, suitable for a development environment, but
nothing more significant.

- ```MEMORY_MAPS_MAX```: Default 8M.
- ```CACHE_DATA_SIZE```: Default 2M.
- ```CACHE_INDEX_SIZE```: Default 2M.
- ```SORT_BUFFER_SIZE```: Default 5M.
- ```WALOG_MAX_SIZE```: Default 5M.

The values Accumulo developers recommend are:

- 512MB:
  - ```MEMORY_MAPS_MAX```: 80M
  - ```CACHE_DATA_SIZE```: 7M
  - ```CACHE_INDEX_SIZE```: 20M
  - ```SORT_BUFFER_SIZE```: 50M
  - ```WALOG_MAX_SIZE```: 100M
- 1GB:
  - ```MEMORY_MAPS_MAX```: 256M
  - ```CACHE_DATA_SIZE```: 15M
  - ```CACHE_INDEX_SIZE```: 40M
  - ```SORT_BUFFER_SIZE```: 50M
  - ```WALOG_MAX_SIZE```: 256M
- 2GB:
  - ```MEMORY_MAPS_MAX```: 512M
  - ```CACHE_DATA_SIZE```: 30M
  - ```CACHE_INDEX_SIZE```: 80M
  - ```SORT_BUFFER_SIZE```: 50M
  - ```WALOG_MAX_SIZE```: 512M.
- 3GB:
  - ```MEMORY_MAPS_MAX```: 1G
  - ```CACHE_DATA_SIZE```: 128M
  - ```CACHE_INDEX_SIZE```: 128M
  - ```SORT_BUFFER_SIZE```: 200M
  - ```WALOG_MAX_SIZE```: 1G

Source at <http://github.com/cybermaggedon/accumulo-docker>.
