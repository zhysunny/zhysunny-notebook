## 版本 0.9.0.1

* 准备环境：jdk，scala，gradle，zookeeper
* 下载kafka源码：[https://github.com/apache/kafka/tree/0.9.0.1](https://github.com/apache/kafka/tree/0.9.0.1)
* 导入idea，导入时提示需要输入gradle安装目录
* 导入后gradle自动build报错
* 由于源码包没有.idea配置文件，需要手动设置代码source，test和resources目录
* 在build.gradle文件最上面加，再build，编译需要很长时间


    ScalaCompileOptions.metaClass.daemonServer = true
    ScalaCompileOptions.metaClass.fork = true
    ScalaCompileOptions.metaClass.useAnt = false
    ScalaCompileOptions.metaClass.useCompileDaemon = false
    
    // repositories下面增加
    mavenLocal()
        maven {
            url "http://maven.aliyun.com/nexus/content/groups/public/"
        }
        
* 编译完成后打开run configuration
    
    
    VM option：-Dkafka.logs.dir=E:\WorkspaceIDEA\kafka-0.9.0.1\logs
    Program arguments：config/server.properties
    
* 将config/log4j.properties文件复制到core/src/main/resources目录下

