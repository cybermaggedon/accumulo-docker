#!/bin/bash

/usr/sbin/sshd
/usr/local/hadoop/sbin/start-dfs.sh
/usr/local/hadoop/bin/hdfs dfsadmin -safemode wait

/usr/local/zookeeper/bin/zkServer.sh start

/usr/local/accumulo/bin/start-all.sh

while true
do
    sleep 10
done

