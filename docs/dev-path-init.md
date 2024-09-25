# 大数据开发环境安装

本章我们将通过 Docker 构建一个大数据开发环境，包含 Hadoop、Zookeeper 和 HBase，通过 Docker
容器进行部署和管理。该环境能够支持分布式数据存储、处理和管理，并为大数据处理任务提供高效的工具链。通过 Docker 的易于管理和扩展特性，本环境可以快速进行设置和配置，适合各种开发场景下的大数据处理工作。

| Java：8.0.352-zulu | Zookeeper：3.9.2      |
|-------------------|----------------------|
| **Maven：3.6.3**   | **HBase：2.5.10-bin** |
| **Hadoop：3.3.6**  |                      |

接下来我们将通过 Docker 进行环境构建，使用自定义的 Dockerfile 定义了整个开发环境的构建流程，包括从基础镜像开始，安装所需的工具和依赖，并下载和配置 Hadoop、Zookeeper、HBase 等组件。并配置环境变量、SSH 无密码登录等功能，确保容器可以无缝运行分布式大数据应用

## 通用环境配置

本小节包括 maven、jdk、ssh 等相关内容

```dockerfile
FROM ubuntu:22.04
LABEL authors="caobaoqi1029"

WORKDIR /root/

# apt 换清华源(使用 http, 因为 https 需要 certificates)
RUN sed -i "s@http://.*.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list

# 安装常用工具和依赖
RUN apt-get update && \
    apt-get install -y wget vim openssh-server net-tools curl git zip && \
    apt-get clean

# SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk version"
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && \
    sdk install java 8.0.352-zulu && \
    sdk install maven 3.6.3"
    
# 设置 JAVA ENV
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV MAVEN_HOME=/root/.sdkman/candidates/maven/current
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# 配置 SSH 免密码登录
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# 启动 bash
CMD ["bash", "-c", "bash"]
```

## hadoop

本小节用于介绍 hadoop 相关安装配置，其中 hadoop：是一个开源的分布式计算框架，支持处理大规模数据集。Hadoop 提供了分布式存储（HDFS）和分布式计算（MapReduce）的核心功能，是大数据生态系统的基石。

```dockerfile
# 下载并解压 Hadoop
RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
#COPY hadoop-3.3.6.tar.gz .
RUN tar -xzvf hadoop-3.3.6.tar.gz && \
    rm hadoop-3.3.6.tar.gz && \
    mv hadoop-3.3.6 hadoop && \
    chmod -R 777 hadoop

# 设置 HADOOP ENV
ENV HADOOP_HOME=/root/hadoop
ENV HADOOP_MAPRED_HOME=/root/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native

RUN mkdir $HADOOP_HOME/tmp
ENV HADOOP_TMP_DIR=$HADOOP_HOME/tmp
RUN mkdir $HADOOP_HOME/namenode
RUN mkdir $HADOOP_HOME/datanode

ENV HADOOP_CONFIG_HOME=$HADOOP_HOME/etc/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

ENV HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_CLASSPATH

ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# 配置 Hadoop
COPY hadoop_config/* /root/hadoop/etc/hadoop/
RUN sed -i '1i export JAVA_HOME=/root/.sdkman/candidates/java/current' /root/hadoop/etc/hadoop/hadoop-env.sh
RUN echo "slave1" >> /root/hadoop/etc/hadoop/workers
RUN echo "slave2" >> /root/hadoop/etc/hadoop/workers
RUN echo "slave3" >> /root/hadoop/etc/hadoop/workers
```

其中 hadoop_config/* 中的各文件内容如下

- core-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/root/hadoop/tmp</value>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master:8020</value>
    </property>
</configuration>
```

- hdfs-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/root/hadoop/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.name.dir</name>
        <value>/root/hadoop/datanode</value>
    </property>
</configuration>
```

- mapred-site.xml

```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>/root/hadoop/share/hadoop/tools/lib/*:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
```

- yarn-site.xml

```xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>
    <!-- Site specific YARN configuration properties -->
    <property>
        <name>yarn.nodemanager.local-dirs</name>
        <value>/root/hadoop/tmp/nm-local-dir</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <!-- ResourceManager Web UI Address -->
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>master:8088</value>
    </property>

    <!-- &lt;!&ndash; ResourceManager scheduler address &ndash;&gt;
 <property>
     <name>yarn.resourcemanager.scheduler.address</name>
     <value>master:8030</value>
 </property>

 &lt;!&ndash; ResourceManager ResourceTracker address &ndash;&gt;
 <property>
     <name>yarn.resourcemanager.resource-tracker.address</name>
     <value>master:8031</value>
 </property>

 &lt;!&ndash; ResourceManager Admin address &ndash;&gt;
 <property>
     <name>yarn.resourcemanager.admin.address</name>
     <value>master:8033</value>
 </property>

 &lt;!&ndash; NodeManager localizer address &ndash;&gt;
 <property>
     <name>yarn.nodemanager.localizer.address</name>
     <value>0.0.0.0:8040</value>
 </property>-->
</configuration>
```



## zookeeper

本小节用于介绍 zookeeper 相关安装配置，其中Apache Zookeeper 是一种开源的分布式协调服务，常用于分布式应用中，提供高效的分布式锁管理、节点状态同步、集群管理等服务

```dockerfile
# 下载并解压 Zookeeper
RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-3.9.2/apache-zookeeper-3.9.2-bin.tar.gz
#COPY apache-zookeeper-3.9.2-bin.tar.gz .
RUN tar -xzvf apache-zookeeper-3.9.2-bin.tar.gz && \
    rm apache-zookeeper-3.9.2-bin.tar.gz && \
    mv apache-zookeeper-3.9.2-bin zookeeper && \
    chmod -R 777 zookeeper

# 设置 Zookeeper ENV
ENV ZOOKEEPER_HOME=/root/zookeeper
ENV PATH=$ZOOKEEPER_HOME/bin:$PATH

# 配置 Zookeeper
RUN mkdir /root/zookeeper/tmp
RUN cp /root/zookeeper/conf/zoo_sample.cfg /root/zookeeper/conf/zoo.cfg
COPY zookeeper_config/* /root/zookeeper/conf/
RUN echo "export HADOOP_CLASSPATH=`hadoop classpath`" >> /root/.bashrc
```

其中 zookeeper_config/* 中的 zoo.cfg 内容如下

```ini
# The number of milliseconds of each tick
tickTime=2000
# The number of ticks that the initial
# synchronization phase can take
initLimit=10
# The number of ticks that can pass between
# sending a request and getting an acknowledgement
syncLimit=5
# the directory where the snapshot is stored.
# do not use /tmp for storage, /tmp here is just
# example sakes.
dataDir=/root/zookeeper/tmp
# the port at which the clients will connect
clientPort=2181
# the maximum number of client connections.
# increase this if you need to handle more clients
#maxClientCnxns=60
#
# Be sure to read the maintenance section of the
# administrator guide before turning on autopurge.
#
# https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
#
# The number of snapshots to retain in dataDir
#autopurge.snapRetainCount=3
# Purge task interval in hours
# Set to "0" to disable auto purge feature
#autopurge.purgeInterval=1

## Metrics Providers
#
# https://prometheus.io Metrics Exporter
#metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
#metricsProvider.httpHost=0.0.0.0
#metricsProvider.httpPort=7000
#metricsProvider.exportJvmInfo=true

server.1=master:2888:3888
server.2=slave1:2888:3888
server.3=slave2:2888:3888
server.4=slave3:2888:3888
```



## hbase

本小节用于介绍 zookeeper 相关安装配置，其中 HBase 是一个基于 Hadoop 的开源分布式数据库，提供对超大规模数据集的高效存储和查询。它特别适用于需要快速读取和写入大数据的场景，如日志处理和实时数据分析

```dockerfile
# 下载并解压 Hbase
RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/2.5.10/hbase-2.5.10-bin.tar.gz
#COPY hbase-2.5.10-bin.tar.gz .
RUN tar -xzvf hbase-2.5.10-bin.tar.gz && \
    rm hbase-2.5.10-bin.tar.gz && \
    mv hbase-2.5.10 hbase && \
    chmod -R 777 hbase

# 设置 Hbase ENV
ENV HBASE_HOME=/root/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

# 配置 Hbase
COPY hbase_config/* /root/hbase/conf
RUN echo "export JAVA_HOME=/root/.sdkman/candidates/java/current" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_MANAGES_ZK=false" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_LIBRARY_PATH=/root/hadoop/lib/native" >> /root/hbase/conf/hbase-env.sh
RUN echo 'export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"' >> /root/hbase/conf/hbase-env.sh
```

其中 hbase_config/* 中的各文件内容如下

- hbase-site.xml

```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
-->
<configuration>
    <!--
      The following properties are set for running HBase as a single process on a
      developer workstation. With this configuration, HBase is running in
      "stand-alone" mode and without a distributed file system. In this mode, and
      without further configuration, HBase and ZooKeeper data are stored on the
      local filesystem, in a path under the value configured for `hbase.tmp.dir`.
      This value is overridden from its default value of `/tmp` because many
      systems clean `/tmp` on a regular basis. Instead, it points to a path within
      this HBase installation directory.

      Running against the `LocalFileSystem`, as opposed to a distributed
      filesystem, runs the risk of data integrity issues and data loss. Normally
      HBase will refuse to run in such an environment. Setting
      `hbase.unsafe.stream.capability.enforce` to `false` overrides this behavior,
      permitting operation. This configuration is for the developer workstation
      only and __should not be used in production!__

      See also https://hbase.apache.org/book.html#standalone_dist
    -->
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://master:8020/hbase</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.tmp.dir</name>
        <value>/root/hbase/tmp</value>
    </property>
    <property>
        <name>hbase.unsafe.stream.capability.enforce</name>
        <value>false</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>slave1:2181,slave2:2181,slave3:2181</value>
    </property>
    <!-- <property>
      <name>hbase.wal.provider</name>
      <value>filesystem</value>
    </property> -->
</configuration>
```

- regionservers

```ini
slave1
slave2
slave3
```

## scripts

用于提供通用脚本

```dockerfile
# scripts
COPY scripts/* /root/scripts/
RUN chmod -R 777 /root/scripts
ENV PATH=/root/scripts:$PATH
```

各文件内容如下

- init.sh

```shell
#! /bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <num>"
  exit 1
fi

num=$1

# 向 myid 文件写入id
echo "$num" > /root/zookeeper/tmp/myid

```

- start_node.sh

```shell
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

```

## 最终文件

![image-20240924152500642](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241525323.png)

```dockerfile
FROM ubuntu:22.04
LABEL authors="caobaoqi1029"

WORKDIR /root/

# apt 换清华源(使用 http, 因为 https 需要 certificates)
RUN sed -i "s@http://.*.ubuntu.com@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list

# 安装常用工具和依赖
RUN apt-get update && \
    apt-get install -y wget vim openssh-server net-tools curl git zip && \
    apt-get clean

# SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk version"
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && \
    sdk install java 8.0.352-zulu && \
    sdk install maven 3.6.3"

# 下载并解压 Hadoop
#RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
COPY hadoop-3.3.6.tar.gz .
RUN tar -xzvf hadoop-3.3.6.tar.gz && \
    rm hadoop-3.3.6.tar.gz && \
    mv hadoop-3.3.6 hadoop && \
    chmod -R 777 hadoop

# 下载并解压 Zookeeper
#RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-3.9.2/apache-zookeeper-3.9.2-bin.tar.gz
COPY apache-zookeeper-3.9.2-bin.tar.gz .
RUN tar -xzvf apache-zookeeper-3.9.2-bin.tar.gz && \
    rm apache-zookeeper-3.9.2-bin.tar.gz && \
    mv apache-zookeeper-3.9.2-bin zookeeper && \
    chmod -R 777 zookeeper

# 下载并解压 Hbase
#RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/2.5.10/hbase-2.5.10-bin.tar.gz
COPY hbase-2.5.10-bin.tar.gz .
RUN tar -xzvf hbase-2.5.10-bin.tar.gz && \
    rm hbase-2.5.10-bin.tar.gz && \
    mv hbase-2.5.10 hbase && \
    chmod -R 777 hbase

# 设置 JAVA ENV
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV MAVEN_HOME=/root/.sdkman/candidates/maven/current
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# 设置 HADOOP ENV
ENV HADOOP_HOME=/root/hadoop
ENV HADOOP_MAPRED_HOME=/root/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native

RUN mkdir $HADOOP_HOME/tmp
ENV HADOOP_TMP_DIR=$HADOOP_HOME/tmp
RUN mkdir $HADOOP_HOME/namenode
RUN mkdir $HADOOP_HOME/datanode

ENV HADOOP_CONFIG_HOME=$HADOOP_HOME/etc/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

ENV HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_CLASSPATH

ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

# 设置 Zookeeper ENV
ENV ZOOKEEPER_HOME=/root/zookeeper
ENV PATH=$ZOOKEEPER_HOME/bin:$PATH

# 设置 Hbase ENV
ENV HBASE_HOME=/root/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

# scripts
COPY scripts/* /root/scripts/
RUN chmod -R 777 /root/scripts
ENV PATH=/root/scripts:$PATH

# 配置 SSH 免密码登录
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# 配置 Hadoop
COPY hadoop_config/* /root/hadoop/etc/hadoop/
RUN sed -i '1i export JAVA_HOME=/root/.sdkman/candidates/java/current' /root/hadoop/etc/hadoop/hadoop-env.sh
RUN echo "slave1" >> /root/hadoop/etc/hadoop/workers
RUN echo "slave2" >> /root/hadoop/etc/hadoop/workers
RUN echo "slave3" >> /root/hadoop/etc/hadoop/workers

# 配置 Zookeeper
RUN mkdir /root/zookeeper/tmp
RUN cp /root/zookeeper/conf/zoo_sample.cfg /root/zookeeper/conf/zoo.cfg
COPY zookeeper_config/* /root/zookeeper/conf/
RUN echo "export HADOOP_CLASSPATH=`hadoop classpath`" >> /root/.bashrc

# 配置 Hbase
COPY hbase_config/* /root/hbase/conf
RUN echo "export JAVA_HOME=/root/.sdkman/candidates/java/current" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_MANAGES_ZK=false" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_LIBRARY_PATH=/root/hadoop/lib/native" >> /root/hbase/conf/hbase-env.sh
RUN echo 'export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"' >> /root/hbase/conf/hbase-env.sh

# 启动 bash
CMD ["bash", "-c", "bash"]
```

# 构建镜像

```shell
cd docker
docker build -t caobaoqi1029/big-data-study:x.x.x .
```

![image-20240924152547805](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241525053.png)

# docker-compose.yaml

```yaml
services:
    master:
        image: caobaoqi1029/big-data-study:0.1.0
        container_name: master
        hostname: master
        ports:
            - "8020:8020"   # HDFS NameNode 主服务端口
            - "9870:9870"   # HDFS NameNode Web UI
            - "8088:8088"   # YARN ResourceManager Web UI
            - "8042:8042"   # YARN NodeManager Web UI
        command: bash -c "/root/scripts/start_node.sh master 1"
        volumes:
            - ./:/root/code-dev
            - ~/.m2:/root/.m2
        networks:
            - hadoop-network
        depends_on:
            - slave1
            - slave2
            - slave3

    slave1:
        image: caobaoqi1029/big-data-study:0.1.0
        container_name: slave1
        hostname: slave1
        command: bash -c "/root/scripts/start_node.sh slave 2"
        networks:
            - hadoop-network

    slave2:
        image: caobaoqi1029/big-data-study:0.1.0
        container_name: slave2
        hostname: slave2
        command: bash -c "/root/scripts/start_node.sh slave 3"
        networks:
            - hadoop-network

    slave3:
        image: caobaoqi1029/big-data-study:0.1.0
        container_name: slave3
        hostname: slave3
        command: bash -c "/root/scripts/start_node.sh slave 4"
        networks:
            - hadoop-network

    firefox:
        image: jlesage/firefox
        container_name: firefox
        hostname: firefox
        ports:
            - "5800:5800" # VNC server port for Firefox
        networks:
            - hadoop-network

networks:
    hadoop-network:
        driver: bridge
```

```shell
docker compose up -d # 项目根目录下（docker-compose.yaml 所在位置）
```

![image-20240924152724130](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241527703.png)

# 验证

```shell
docker exec -it master bash
jps
```

![image-20240924153421011](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241534493.png)

```shell
ssh slave1
jps
```

![image-20240924153452204](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241534341.png)

## 访问 http://localhost:8020/

![image-20240924153541707](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241535319.png)

## 访问 http://localhost:9870/

![image-20240924153609303](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241536152.png)

![image-20240924153627388](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241536723.png)

## 访问 http://localhost:8088/

![image-20240924153704070](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241537900.png)

## 访问 http://localhost:8042/

![image-20240924153727767](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241537584.png)

## 通过访问容器内 firefox 进行验证 http://localhost:5800/

- http://master:8088

![image-20240924191331370](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241913194.png)