#! /bin/bash

# 获取主机名并去除数字，得到节点类型
NODE_TYPE=$(hostname | sed 's/[0-9]*//g')

# 输出推断的节点类型
echo "Node type determined from hostname: $NODE_TYPE"

# 根据节点类型执行不同操作
if [ "$NODE_TYPE" == "master" ]; then
  # 停止 Hbase、Zookeeper 和 Hadoop 集群
  stop-hbase.sh
  zkServer.sh stop
  stop-all.sh
elif [ "$NODE_TYPE" == "slave" ]; then
  # 停止 Zookeeper
  zkServer.sh stop
else
  echo "Unknown node type: $NODE_TYPE"
  exit 1
fi

# 停止 SSH 服务
service ssh stop

echo "$NODE_TYPE node services stopped."
