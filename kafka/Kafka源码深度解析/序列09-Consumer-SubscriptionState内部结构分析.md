# 序列09-Consumer-SubscriptionState内部结构分析

在前面讲了，KafkaConsumer的一个重要部件就是SubscriptionState，这个部件维护了Consumer的消费状态，本篇对其内部结构进行分析。

## 2种订阅策略
在第1篇讲过，consumer可以自己指定要消费哪个partition，而不是让consumer leader自动分配，对应的，也就是调用 
KakfaConsumer::assign(List partitions)函数。

另外1种策略是调用subscrible，只指定要消费的topic，然后由前面所讲的coordinator协议，自动分配partition。

下面的SubscriptionState的结构，就反映了这2种不同的策略:
```
public class SubscriptionState {
    //该consumer订阅的所有topics
    private final Set<String> subscription;

    //该consumer所属的group中，所有consumer订阅的topic。该字段只对consumer leader有用
    private final Set<String> groupSubscription;

    //策略1：consumer 手动指定partition, 该字段不为空
    //策略2：consumer leader自动分配，该字段为空
    private final Set<TopicPartition> userAssignment;

    //partition分配好之后，该字段记录每个partition的消费状态(策略1和策略2，都需要这个字段）
    private final Map<TopicPartition, TopicPartitionState> assignment;
    。。。
```
这里一个关键点：策略1和策略2是互斥的，也就是说，如果调了assign函数，再调subscrible，会直接抛异常出来:
```
public void subscribe(List<String> topics, ConsumerRebalanceListener listener) 
{
 if (listener == null) throw new IllegalArgumentException("RebalanceListener cannot be null"); 

if (!this.userAssignment.isEmpty() || this.subscribedPattern != null) throw new IllegalStateException(SUBSCRIPTION_EXCEPTION_MESSAGE);  //关键点

this.listener = listener; changeSubscription(topics); 
}
```

## 2个offset
在前面我们讲了，一个TopicPartition其实有2个offset，一个是当前要消费的offset(poll的时候），一个是消费确认过的offset。

因此在上面的TopicPartitionState这个结构中，有2个字段：
```
//SubscriptionState中的字段
 private final Map<TopicPartition, TopicPartitionState> assignment;

//TopicPartitionState内部结构
    private static class TopicPartitionState {
        private Long position;  //字段1：记录当前要消费的offset
        private OffsetAndMetadata committed; //字段2：记录已经commit过的offset
        ...
    }

public class OffsetAndMetadata implements Serializable {
    private final long offset;
    private final String metadata; //额外字段，可以不用。比如客户端可以记录哪个client, 什么时间点做的这个commit
    ...
 }
```
其中字段1是在上面Fetcher的第3步 fetchedRecords里面进行更新的：
```
public Map<TopicPartition, List<ConsumerRecord<K, V>>> fetchedRecords() {
        if (this.subscriptions.partitionAssignmentNeeded()) {
            return Collections.emptyMap();
        } else {
            Map<TopicPartition, List<ConsumerRecord<K, V>>> drained = new HashMap<>();
            throwIfOffsetOutOfRange();
            throwIfUnauthorizedTopics();
            throwIfRecordTooLarge();

            for (PartitionRecords<K, V> part : this.records) {
                if (!subscriptions.isAssigned(part.partition)) {
                    log.debug("Not returning fetched records for partition {} since it is no longer assigned", part.partition);
                    continue;
                }

                long position = subscriptions.position(part.partition);
                if (!subscriptions.isFetchable(part.partition)) {
                    log.debug("Not returning fetched records for assigned partition {} since it is no longer fetchable", part.partition);
                } else if (part.fetchOffset == position) {
                   //关键：计算下1个offset
                    long nextOffset = part.records.get(part.records.size() - 1).offset() + 1;
                    ...

                    //更新SubscriptionState中的字段1
                    subscriptions.position(part.partition, nextOffset);
                } else {

                    log.debug("Ignoring fetched records for {} at offset {} since the current position is {}",
                            part.partition, part.fetchOffset, position);
                }
            }
            this.records.clear();
            return drained;
        }
    }
```

字段2，显然是在手动commit或者自动commit之后，进行更新（关于这2种commit策略，前面已经讲述）

## 总结
结合序列8，此处总结一下consumer的几个方面的策略：

（1）assign vs. subscribe (手动指定partition vs. 自动为其分配partition)

（2）手动指定初始offset(seek) vs. 自动获取初始offset(发送OffsetFetchRequest请求)

（3）手动消费确认 vs. 自动消费确认(AutoCommitTask)