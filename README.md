Accumulo container, needs Hadoop HDFS and Zookeeper.

Simplest scenario, single node Hadoop, single node Zookeeper, single node
Accumulo, no persistence.  Accumulo uses hostname 'hadoop' for HDFS by default,
and 'zookeeper' for Zookeeper.

```
  # Start Hadoop
  docker run -d --name hadoop cybermaggedon/hadoop:3.2.0

  # Start Zookeeper
  docker run -d --name zookeeper cybermaggedon/zookeeper:3.6.1

  # Start Accumulo, linking to other containers.
  docker run -d --name accumulo -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
	--link zookeeper:zookeeper \
        cybermaggedon/accumulo:2.0.0-alpha-2

```

To check Accumulo works:

```
  % docker exec -it accumulo bash
  # accumulo shell
  root@accumulo> tables

```
... and you should see a list of tables.

If you want to persist Accumulo you will need to ensure Hadoop and Zookeeper
are persistent.  Here we are using /data/hadoop and /data/zookeeper as
persistent volumes.

e.g.

```
  # Start Hadoop
  docker run -d --name hadoop -v /data/hadoop:/data cybermaggedon/hadoop:3.2.0

  # Start Zookeeper
  docker run -d --name zookeeper -v /data/zookeeper:/data \
        cybermaggedon/zookeeper:3.6.1

  # Start Accumulo, linking to other containers.
  docker run -d --name accumulo  -p 9995:9995 -p 9997:9997 -p 9999:9999 \
        --link hadoop:hadoop \
        --link zookeeper:zookeeper \
	cybermaggedon/accumulo:1.9.3a

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
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      cybermaggedon/hadoop:3.2.0 /start-namenode

  # Datanodes
  docker run -d --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  docker run -d --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  ############################################################################
  # Zookeeper cluster, 3 nodes.
  ############################################################################
  docker run -d --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      cybermaggedon/zookeeper:3.6.1

  ############################################################################
  # Accumulo, 3 nodes
  ############################################################################
  docker run -d --ip=10.10.10.10 --net my_network \
      -p 50095:50095 -p 9995:9995 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e DAEMONS=master,tserver,gc,monitor,tracer \
      --link hadoop01:hadoop01 \
      --name acc01 cybermaggedon/accumulo:1.9.3a

  docker run -d --ip=10.10.10.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      --link hadoop01:hadoop01 \
      --name acc02 cybermaggedon/accumulo:1.9.3 \
      /start-process tserver

  docker run -d --ip=10.10.10.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e DAEMONS=tserver \
      --link hadoop01:hadoop01 \
      --name acc03 cybermaggedon/accumulo:1.9.3 \
      /start-process tserver

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
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      -v /data/hadoop01:/data \
      cybermaggedon/hadoop:3.2.0 /start-namenode

  # Datanodes
  docker run -d --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      -v /data/hadoop02:/data \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  docker run -d --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      -v /data/hadoop03:/data \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  ############################################################################
  # Zookeeper cluster, 3 nodes.
  ############################################################################
  docker run -d --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      -v /data/zk1:/data \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      -v /data/zk2:/data \
      cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      -v /data/zk3:/data \
      cybermaggedon/zookeeper:3.6.1

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
      --name acc01 cybermaggedon/accumulo:1.9.3a

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
      --name acc02 cybermaggedon/accumulo:1.9.3a

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
      --name acc03 cybermaggedon/accumulo:1.9.3a

```
Now, the above configuration has a problem, in that it uses the default
Accumulo startup.  This runs all of the Accumulo processes in the background
inside each container.  If Accumulo processes fail, there's no restart.  The
Docker Way to do this is to run each Accumulo process in its own container,
so that when the process fails, the container fails, which can be detected
and restarted.  To do this, I invoke /start-process and provide the name of
an Accumulo process to stat.

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
      --name=hadoop01 \
      -p 50070:50070 -p 50075:50075 -p 50090:50090 -p 9000:9000 \
      -v /data/hadoop01:/data \
      cybermaggedon/hadoop:3.2.0 /start-namenode

  # Datanodes
  docker run -d --ip=10.10.6.4 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop02 \
      -v /data/hadoop02:/data \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  docker run -d --ip=10.10.6.5 --net my_network --link hadoop01:hadoop01 \
      -e NAMENODE_URI=hdfs://hadoop01:9000 \
      --name=hadoop03 \
      -v /data/hadoop03:/data \
      cybermaggedon/hadoop:3.2.0 /start-datanode

  ############################################################################
  # Zookeeper cluster, 3 nodes.
  ############################################################################
  docker run -d --ip=10.10.5.10 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=1 \
      -v /data/zk1:/data \
      --name zk1 -p 2181:2181 cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=2 --name zk2 --link zk1:zk1 \
      -v /data/zk2:/data \
      cybermaggedon/zookeeper:3.6.1
      
  docker run -d --ip=10.10.5.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e ZOOKEEPER_MYID=3 --name zk3 --link zk1:zk1 \
      -v /data/zk3:/data \
      cybermaggedon/zookeeper:3.6.1

  ############################################################################
  # Accumulo, 3 nodes
  ############################################################################

  # Master
  docker run -d --ip=10.10.10.10 --net my_network \
      -p 50095:50095 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.10 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-master cybermaggedon/accumulo:1.9.3a /start-process master

  # GC
  docker run -d --ip=10.10.10.11 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.11 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-gc cybermaggedon/accumulo:1.9.3a /start-process gc

  # Slave 1
  docker run -d --ip=10.10.10.12 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.12 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-slave1 cybermaggedon/accumulo:1.9.3a /start-process tserver

  # Slave 2
  docker run -d --ip=10.10.10.13 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.13 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-slave2 cybermaggedon/accumulo:1.9.3a /start-process tserver

  # Slave 3
  docker run -d --ip=10.10.10.14 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.14 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-slave3 cybermaggedon/accumulo:1.9.3a /start-process tserver

  # Monitor - this has the web server.
  docker run -d --ip=10.10.10.15 --net my_network \
      -p 9995:9995 \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.15 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-monitor cybermaggedon/accumulo:1.9.3a /start-process monitor

  docker run -d --ip=10.10.10.16 --net my_network \
      -e ZOOKEEPERS=10.10.5.10,10.10.5.11,10.10.5.12 \
      -e HDFS_VOLUMES=hdfs://hadoop01:9000/accumulo \
      -e NAMENODE_URI=hdfs://hadoop01:9000/ \
      -e MY_HOSTNAME=10.10.10.16 \
      -e MASTER_HOSTS=10.10.10.10 \
      -e GC_HOSTS=10.10.10.11 \
      -e SLAVE_HOSTS=10.10.10.12,10.10.10.13,10.10.10.14 \
      -e MONITOR_HOSTS=10.10.10.15 \
      -e TRACER_HOSTS=10.10.10.16 \
      --link hadoop01:hadoop01 \
      --name acc-tracer cybermaggedon/accumulo:1.9.3a /start-process tracer

```

If volumes don't mount because of selinux, this command may be your friend:

  ```chcon -Rt svirt_sandbox_file_t /path/of/volume```

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
