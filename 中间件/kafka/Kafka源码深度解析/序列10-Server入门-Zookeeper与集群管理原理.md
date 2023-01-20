# 序列10-Server入门-Zookeeper与集群管理原理

从本篇开始，我们进入服务器端的源码分析。在正式进入服务器源码分析之前，需要先从宏观上对Kafka的集群管理有一个基本了解。

在序列1里面，我们画了Kafka集群的物理架构图，知道所有的broker启动之后，都会连接到Zookeeper上面。那具体来讲，Zookeeper要帮助Kafka完成什么工作呢？

## 集群管理的思路
### broker的“生“与“死“
任何时候，当集群中有1个新的broker加入，或者某个旧的broker死亡，集群中其它机器都需要知道这件事。

其实现方式就是监听Zookeeper上面的/broker/ids结点，其每个子结点就对应1台broker机器，当broker机器添加，子结点列表增大；broker机器死亡，子结点列表减小。

### Controller
为了减小Zookeeper的压力，同时也降低整个分布式系统的复杂度，Kafka引入了一个“中央控制器“，也就是Controller。 
其基本思路是：先通过Zookeeper在所有broker中选举出一个Controller，然后用这个Controller来控制其它所有的broker，而不是让zookeeper直接控制所有的机器。 
比如上面对/broker/ids的监听，并不是所有broker都监听此结点，而是只有Controller监听此结点，这样就把一个“分布式“问题转化成了“集中式“问题，即降低了Zookeeper负担，也便于控制逻辑的编写。

### topic与partition的增加／删除
同样，作为1个分布式集群，当增加／删除一个topic或者partition的时候，不可能挨个通知集群的每1台机器。

这里的实现思路也是：管理端(Admin/TopicCommand)把增加/删除命令发送给Zk，Controller监听Zk获取更新消息, Controller再分发给相关的broker。

### I0ITec ZkClient
关于Zookeeper的客户端，我们知道常用的有Apache Curator，但Kafka用的不是这个。而是另外一个叫做I0ITec ZkClient的，记得没错的话，阿里的dubbo框架，也用的这个。相对Curator，它更加轻量级。

具体来说，其主要有3个Listener:
```
//当某个session断了重连，就会调用这个监听器
public interface IZkStateListener {
    public void handleStateChanged(KeeperState state) throws Exception;

    public void handleNewSession() throws Exception;

    public void handleSessionEstablishmentError(final Throwable error) throws Exception;

}

//当某个结点的data变化之后（data变化，或者结点本事被删除）
public interface IZkDataListener {

    public void handleDataChange(String dataPath, Object data) throws Exception;

    public void handleDataDeleted(String dataPath) throws Exception;
}

//当某个结点的子结点发生变化
public interface IZkChildListener {
    public void handleChildChange(String parentPath, List<String> currentChilds) throws Exception;
}
```
Kafka正是利用上面3个listener实现了所有zookeeper相关状态变化的监听，其具体应用，将在后续序列逐个展开！