#!/bin/bash

/usr/sbin/sshd

/usr/local/hadoop/bin/hdfs namenode -format

/usr/local/hadoop/sbin/start-dfs.sh
/usr/local/hadoop/bin/hdfs dfsadmin -safemode wait

/usr/local/zookeeper/bin/zkServer.sh start

/usr/local/accumulo/bin/accumulo init --instance-name accumulo --password accumulo

/usr/local/zookeeper/bin/zkServer.sh stop
/usr/local/hadoop/sbin/stop-dfs.sh

ps -ef | grep sshd | grep -v grep | awk '{print $2}' | xargs kill


