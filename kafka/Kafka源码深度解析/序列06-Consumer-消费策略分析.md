# 序列06-Consumer-消费策略分析

## Consumer的非线程安全

在前面我们讲到，KafkaProducer是线程安全的，可以多个线程共享一个producer实例。但Consumer却不是。

在KafkaConsumer的几乎所有函数中，我们都会看到这个：
```
public ConsumerRecords<K, V> poll(long timeout) {
    acquire();   //这里的acquire/release不是为了多线程加锁，恰恰相反：是为了防范多线程调用。如果发现多线程调用，内部会直接抛异常出来
    ...
    release(); 
}
```

## Consumer Group – 负载均衡模式 vs. Pub/Sub模式

每一个consumer实例，在初始化的时候，都需要传一个group.id，这个group.id决定了多个Consumer在消费同一个topic的时候，是分摊，还是广播。

假设多个Consumer都订阅了同一个topic，这个topic有多个partition.

负载均衡模式： 多个Consumer属于同一个group，则topic对应的partition的消息会分摊到这些Consumer上。

Pub/Sub模式：多个Consumer属于不同的group，则这个topic的所有消息，会广播到每一个group。

## Partition 自动分配 vs. 手动指定

在上面的负载均衡模式中，我们调用subscrible函数，只指定了topic，不指定partition，这个时候，partition会自动在这个group的所有对应consumer中分摊。

另外一种方式是，强制指定consumer消费哪个topic的哪个partion，使用的是assign函数。
```
public void subscribe(List<String> topics) {
    subscribe(topics, new NoOpConsumerRebalanceListener());
}

public void assign(List<TopicPartition> partitions) {
    。。。
}
```

一个关键点是：这2种模式是互斥的，使用了subscribe，就不能使用assign。反之亦然。

在代码中，这2种模式，是分别存放在2个不同的变量中：
```
public class SubscriptionState {
    。。。
    private final Set<String> subscription;  //对应subscrible模式
    private final Set<TopicPartition> userAssignment; //对应assign模式
}
```

同样，代码中调用subscrible或者assign的时候，有相应的检查。如果发现互斥，会抛异常出来。

## 消费确认 - consume offset vs. committed offset

在前面我们提到，“消费确认”是所有消息中间件都要解决的一个问题：拿到消息之后，处理完毕，向消息中间件发送ack，或者说confirm。

那这里就会涉及到2个消费位置，或者说2个offset值： 一个是当前取消息所在的consume offset，一个是处理完毕，发送ack之后所确定的committed offset。

很显然，在异步模式下，committed offset要落后于consume offset。

这里的一个关键点：假如consumer挂了重启，那它将从committed offset位置开始重新消费，而不是consume offset位置。这也就意味着有可能重复消费

在0.9客户端中，有3种ack策略： 
策略1： 自动的，周期性的ack。也就是上面demo所展示的方式：
```
props.put("enable.auto.commit", "true");
props.put("auto.commit.interval.ms", "1000");
```

策略2：consumer.commitSync() //调用commitSync，手动同步ack。每处理完1条消息，commitSync 1次

策略3：consumer. commitASync() //手动异步ack

## Exactly Once – 自己保存offset

在前面我们讲过，Kafka只保证消息不漏，即at lease once，而不保证消息不重。

重复发送：这个客户端解决不了，需要服务器判重，代价太大。

重复消费：有了上面的commitSync()，我们可以每处理完1条消息，就发送一次commitSync。那这样是不是就可以解决“重复消费”了呢？就像下面的代码：
```
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(100);
    for (ConsumerRecord<String, String> record : records) {
     buffer.add(record);
    }
    if (buffer.size() >= minBatchSize) {
     insertIntoDb(buffer);    //消除处理，存到db
     consumer.commitSync();   //同步发送ack
     buffer.clear();
    }
}
```

答案是否定的！因为上面的insertIntoDb和commitSync做不到原子操作：如果在数据处理完成，commitSync的时候挂了，服务器再次重启，消息仍然会重复消费。

那这个问题有什么解决办法呢？

答案是自己保存committed offset，而不是依赖kafka的集群保存committed offset，把消息的处理和保存offset做成一个原子操作。

在kafka的官方文档中，列举了以下2种自己保存offset的使用场景：
```
//关系数据库，通过事务存取。consumer挂了，重启，消息也不会重复消费
If the results of the consumption are being stored in a relational database, storing the offset in the database as well can allow committing both the results and offset in a single transaction. Thus either the transaction will succeed and the offset will be updated based on what was consumed or the result will not be stored and the offset won't be updated.

//搜索引擎：把offset跟数据一起，建在索引里面
If the results are being stored in a local store it may be possible to store the offset there as well. For example a search index could be built by subscribing to a particular partition and storing both the offset and the indexed data together. If this is done in a way that is atomic, it is often possible to have it be the case that even if a crash occurs that causes unsync'd data to be lost, whatever is left has the corresponding offset stored as well. This means that in this case the indexing process that comes back having lost recent updates just resumes indexing from what it has ensuring that no updates are lost.
```

同时，官方也说了，要自己保存offset，就需要做以下几个操作
```
Configure enable.auto.commit=false   //禁用自动ack
Use the offset provided with each ConsumerRecord to save your position. //每次取到消息，把对应的offset存下来
On restart restore the position of the consumer using seek(TopicPartition, long).//下次重启，通过consumer.seek函数，定位到自己保存的offset，从那开始消费
```

通过上述办法，我们也就达到了在消费端的 ”Exactly Once “，在消费端，消息不丢，不重。

更进一步把producer + consumer合在一起思考，如果有了消费端的Exactly Once，再加上DB的判重，即使发送端有“重复发送”，也没问题了。
