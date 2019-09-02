# Hive的安装

### 一、安装mysql
详情见 [mysql安装.md]()

### 部署开源包(hive-1.2.2)

##### 1.解压hive安装包apache-hive-1.2.2-bin.tar.gz
    
    tar -xvf apache-hive-1.2.2-bin.tar.gz
    
##### 2.配置环境变量：HIVE_HOME和PATH
    
##### 3.修改配置文件

    # 复制默认配置文件
    cp hive-default.xml.template hive-default.xml
    vi hive-default.xml
    %s#${system:java.io.tmpdir}/${system:user.name}#/data/apps/hive-1.2.2/tmp#g  #修改3处
    %s#${system:java.io.tmpdir}#/data/apps/hive-1.2.2/tmp#g  #修改1处
    
    # 新增hive-site.xml文件，或者复制hive-default.xml配置
    <!-- 数据库配置 开始 -->
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost:3306/hive?createDatabaseIfNotExist=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>root</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>123456</value>
    </property>
    <!-- 数据库配置 结束 -->
    
    <!-- 其他配置 -->
    <!-- client状态下表字段是否显示 -->
    <property>
        <name>hive.cli.print.header</name>
        <value>true</value>
    </property>
    <!-- 是否可以分桶 -->
    <property>
        <name>hive.enforce.bucketing</name>
        <value>true</value>
    </property>
    
    # 删除hadoop jline包，并复制hive下的jline包到hadoop目录下(可以不复制)
    rm -rf ${HADOOP_HOME}/share/hadoop/yarn/lib/jline*.jar
    cp ${HIVE_HOME}/lib/jline*.jar ${HADOOP_HOME}/share/hadoop/yarn/lib

##### 4.启动hive

执行 **hive** 命令，进入hive交互模式，并初始化mysql元数据库
