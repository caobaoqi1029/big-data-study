# 单词计数

通过 hadoop 实现统计文件中单词出现的次数

1. init file

   ```bash
   vim input.txt
   hdfs dfs -put -f ./input.txt /
   hdfs dfs -ls /
   ```

   ![image-20240924155424270](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241554611.png)

2. build jar and run it

   ```bash
   mvn install
   cd @code
   mvn clean package
   cd target/
   hadoop jar big-data.jar
   ```
   
   ![image-20240924155701692](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241557451.png)
   
   ![image-20240924155759912](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241558976.png)
   
   >  [!TIP]
   >
   >  You can set the environment variable to run Java directly
   
    ```bash
    export CLASSPATH=$CLASSPATH:/tmp/ # Add this to .bashrc for persistence.
    ```
   
   ![image-20240924155459844](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241555203.png)
   
3. view the output

   ```bash
   hdfs dfs -ls /output
   hdfs dfs -cat /output/part-r-00000
   ```

![image-20240924155918737](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409241559306.png)

# LsFileContent

> [!TIP]
>
> - 需要 vscode 中安装 Extension Pack for Java 拓展
> - 确保 `export CLASSPATH=$CLASSPATH:/tmp/` 正确写入到 .bashrc

![image-20240925093242404](https://mcddhub-1311841992.cos.ap-beijing.myqcloud.com/picgo/202409250932723.png)

