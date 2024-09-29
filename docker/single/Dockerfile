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

COPY dev-zips .

RUN tar -xzvf hadoop-3.3.6.tar.gz && \
    rm hadoop-3.3.6.tar.gz && \
    mv hadoop-3.3.6 hadoop && \
    chmod -R 777 hadoop

RUN tar -xzvf hbase-2.5.10-bin.tar.gz && \
    rm hbase-2.5.10-bin.tar.gz && \
    mv hbase-2.5.10 hbase && \
    chmod -R 777 hbase

RUN tar -xzvf apache-hive-3.1.3-bin.tar.gz && \
    rm apache-hive-3.1.3-bin.tar.gz  && \
    mv apache-hive-3.1.3-bin hive && \
    chmod -R 777 hive

RUN tar -xzvf spark-3.4.3-bin-without-hadoop.tgz && \
    rm spark-3.4.3-bin-without-hadoop.tgz && \
    mv spark-3.4.3-bin-without-hadoop spark && \
    chmod -R 777 spark

# 设置 JAVA ENV
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV MAVEN_HOME=/root/.sdkman/candidates/maven/current
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# 设置 HADOOP ENV
ENV HADOOP_HOME=/root/hadoop
ENV HADOOP_MAPRED_HOME=/root/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_CONFIG_HOME=$HADOOP_HOME/etc/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
ENV HADOOP_CLASSPATH=$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_CLASSPATH
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
# 设置 Hbase ENV
ENV HBASE_HOME=/root/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

# 设置 HIVE ENV
ENV HIVE_HOME=/root/hive
ENV PATH=$HIVE_HOME/bin:$PATH

# 设置 SPARK ENV
ENV SPARK_HOME=/root/spark
ENV PATH=$SPARK_HOME/bin:$PATH

# 配置 Hadoop
COPY hadoop_config/* /root/hadoop/etc/hadoop/
RUN sed -i '1i export JAVA_HOME=/root/.sdkman/candidates/java/current' /root/hadoop/etc/hadoop/hadoop-env.sh

# 配置 Hbase
COPY hbase_config/* /root/hbase/conf
RUN echo "export JAVA_HOME=/root/.sdkman/candidates/java/current" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_CLASSPATH=/usr/local/hbase/conf" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_LIBRARY_PATH=/root/hadoop/lib/native" >> /root/hbase/conf/hbase-env.sh
RUN echo "export HBASE_MANAGES_ZK=true" >> /root/hbase/conf/hbase-env.sh

# 配置 Hive
COPY hive_config/* /root/hive/conf
RUN cp mysql-connector-java-5.1.40.jar /root/hive/lib

# 配置 Spark
RUN echo "export SPARK_DIST_CLASSPATH=$(/root/hadoop/bin/hadoop classpath)" >> /root/spark/conf/spark-env.sh


# 配置 SSH 免密码登录
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# 启动 bash
CMD ["bash", "-c", "bash"]