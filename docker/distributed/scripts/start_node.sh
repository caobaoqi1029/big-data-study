#! /bin/bash

# 参数检查
if [ $# -lt 2 ]; then
  echo "Usage: $0 <node_type> <zookeeper_id>"
  exit 1
fi

NODE_TYPE=$1
ZK_ID=$2

# 启动 SSH 服务
service ssh restart

# 根据节点类型执行不同操作
if [ "$NODE_TYPE" == "master" ]; then
  # 格式化 Namenode 并启动 Hadoop 集群
  hdfs namenode -format -force
  start-all.sh

  # 初始化 Zookeeper 和 Hbase
  /root/scripts/init.sh "$ZK_ID"
  zkServer.sh start
  start-hbase.sh
elif [ "$NODE_TYPE" == "slave" ]; then
  # 初始化 Zookeeper
  /root/scripts/init.sh "$ZK_ID"
  zkServer.sh start
fi

# 保持容器运行
tail -f /dev/null
