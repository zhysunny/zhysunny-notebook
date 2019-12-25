## Topic相关指标

* Topic消息入站速率（Byte）

kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec,topic=" + topic

* Topic消息出站速率（Byte）

kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec,topic=" + topic

* Topic请求被拒速率

kafka.server:type=BrokerTopicMetrics,name=BytesRejectedPerSec,topic=" + topic

* Topic失败拉去请求速率

kafka.server:type=BrokerTopicMetrics,name=FailedFetchRequestsPerSec,topic=" + topic;

* Topic发送请求失败速率

kafka.server:type=BrokerTopicMetrics,name=FailedProduceRequestsPerSec,topic=" + topic

* Topic消息入站速率（message）

kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec,topic=" + topic

## Broker相关指标

1.log刷新速度和时间

kafka.log:type=LogFlushStats,name=LogFlushRateAndTimeMs

2.同步失效的副本数

kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions

3.消息入站速率（消息数）

kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec

4.消息入站速率（Byte）

kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec

5.消息出站速率（Byte）

kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec

6.请求被拒速率

kafka.server:type=BrokerTopicMetrics,name=BytesRejectedPerSec

7.失败拉去请求速率

kafka.server:type=BrokerTopicMetrics,name=FailedFetchRequestsPerSec

8.发送请求失败速率

kafka.server:type=BrokerTopicMetrics,name=FailedProduceRequestsPerSec

9.Leader副本数

kafka.server:type=ReplicaManager,name=LeaderCount

10.Partition数量

kafka.server:type=ReplicaManager,name=PartitionCount

11.下线Partition数量

kafka.controller:type=KafkaController,name=OfflinePartitionsCount

12.Broker网络处理线程空闲率

kafka.server:type=KafkaRequestHandlerPool,name=RequestHandlerAvgIdlePercent

13.Leader选举比率

kafka.controller:type=ControllerStats,name=LeaderElectionRateAndTimeMs

14.Unclean Leader选举比率

kafka.controller:type=ControllerStats,name=UncleanLeaderElectionsPerSec

15.Controller存活

kafka.controller:type=KafkaController,name=ActiveControllerCount

16.请求速率

kafka.network:type=RequestMetrics,name=RequestsPerSec,request=Produce

17.Consumer拉取速率

kafka.network:type=RequestMetrics,name=RequestsPerSec,request=FetchConsumer

18.Follower拉去速率

kafka.network:type=RequestMetrics,name=RequestsPerSec,request=FetchFollower

19.请求的总时间

kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Produce

20.消费者获取总时间

kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchConsumer

21.Follower获取总时间

kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchFollower

22.Follower获取请求在请求队列中等待的时间

kafka.network:type=RequestMetrics,name=RequestQueueTimeMs,request=FetchFollower

23.消费者获取请求在请求队列中等待的时间

kafka.network:type=RequestMetrics,name=RequestQueueTimeMs,request=FetchConsumer

24.生产者获取请求在请求队列中等待的时间

kafka.network:type=RequestMetrics,name=RequestQueueTimeMs,request=Produce

25.Broker I/O工作处理线程空闲率

kafka.network:type=SocketServer,name=NetworkProcessorAvgIdlePercent

26.ISR变化速率

kafka.server:type=ReplicaManager,name=IsrShrinksPerSec
