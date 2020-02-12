# 序列08-Consumer-Fetcher实现原理与offset确认机制

## KafkaConsumer的几个核心部件
在进一步介绍之前，我们先通过KafkaConsumer的构造函数，看一下其核心部件：
```
private KafkaConsumer(ConsumerConfig config,
                          Deserializer<K> keyDeserializer,
                          Deserializer<V> valueDeserializer) {
        try {
            ...
            //Metadata
            this.metadata = new Metadata(retryBackoffMs, config.getLong(ConsumerConfig.METADATA_MAX_AGE_CONFIG));

            ...
            //NetworkClient
            ChannelBuilder channelBuilder = ClientUtils.createChannelBuilder(config.values());
            NetworkClient netClient = new NetworkClient(
                    new Selector(config.getLong(ConsumerConfig.CONNECTIONS_MAX_IDLE_MS_CONFIG), metrics, time, metricGrpPrefix, metricsTags, channelBuilder),
                    this.metadata,
                    clientId,
                    100, // a fixed large enough value will suffice
                    config.getLong(ConsumerConfig.RECONNECT_BACKOFF_MS_CONFIG),
                    config.getInt(ConsumerConfig.SEND_BUFFER_CONFIG),
                    config.getInt(ConsumerConfig.RECEIVE_BUFFER_CONFIG),
                    config.getInt(ConsumerConfig.REQUEST_TIMEOUT_MS_CONFIG), time);

            ...
            //ConsumerNetworkClient
            this.client = new ConsumerNetworkClient(netClient, metadata, time, retryBackoffMs);
            OffsetResetStrategy offsetResetStrategy = OffsetResetStrategy.valueOf(config.getString(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG).toUpperCase());

            ...
            //SubscriptionState
            this.subscriptions = new SubscriptionState(offsetResetStrategy);
            List<PartitionAssignor> assignors = config.getConfiguredInstances(
                    ConsumerConfig.PARTITION_ASSIGNMENT_STRATEGY_CONFIG,
                    PartitionAssignor.class);

            ...
            //ConsumerCoordinator
            this.coordinator = new ConsumerCoordinator(this.client,
                    config.getString(ConsumerConfig.GROUP_ID_CONFIG),
                    config.getInt(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG),
                    config.getInt(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG),
                    assignors,
                    this.metadata,
                    this.subscriptions,
                    metrics,
                    metricGrpPrefix,
                    metricsTags,
                    this.time,
                    retryBackoffMs,
                    new ConsumerCoordinator.DefaultOffsetCommitCallback(),
                    config.getBoolean(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG),
                    config.getLong(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG));
            if (keyDeserializer == null) {
                this.keyDeserializer = config.getConfiguredInstance(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
                        Deserializer.class);
            ...
            //Fetcher    
            this.fetcher = new Fetcher<>(this.client,
                    config.getInt(ConsumerConfig.FETCH_MIN_BYTES_CONFIG),
                    config.getInt(ConsumerConfig.FETCH_MAX_WAIT_MS_CONFIG),
                    config.getInt(ConsumerConfig.MAX_PARTITION_FETCH_BYTES_CONFIG),
                    config.getBoolean(ConsumerConfig.CHECK_CRCS_CONFIG),
                    this.keyDeserializer,
                    this.valueDeserializer,
                    this.metadata,
                    this.subscriptions,
                    metrics,
                    metricGrpPrefix,
                    metricsTags,
                    this.time,
                    this.retryBackoffMs);

        ...
    }
```
从上面代码可以看出，KafkaConsumer有以下几个核心部件： 
(1)Metedata //同KafkaProducer 
(2)NetworkClient //同KafkaProducer 
(3)ConsumerNetworkClient //对NetworkClient的封装，后面再详细讲述 
(4)ConsumerCoordinator //上1篇所讲的，负责partitiion的分配，reblance 
(5)SubscriptionState //订阅的TopicPartition的offset状态维护 
(6)Fetcher //获取消息

本篇将对Fetcher + SubscriptionState进行详细讲述。

## Fetcher流程介绍
下面分析一下consumer poll的整个流程，这其中也就包含了Fetcher的流程：
```
private Map<TopicPartition, List<ConsumerRecord<K, V>>> pollOnce(long timeout) {
        //上一篇已经分析：确保先找到coordinator
        coordinator.ensureCoordinatorKnown();

        // 上一篇已经分析：每个consumer得到自己分配到的partition
        if (subscriptions.partitionsAutoAssigned())
            coordinator.ensurePartitionAssignment();

        // offset的初始化问题：本篇来分析
        if (!subscriptions.hasAllFetchPositions())
            updateFetchPositions(this.subscriptions.missingFetchPositions());

        Cluster cluster = this.metadata.fetch();
        Map<TopicPartition, List<ConsumerRecord<K, V>>> records = fetcher.fetchedRecords();
        if (!records.isEmpty()) {
            return records;
        }

        //fetcher的3个步骤
        //步骤1：生成FetchRequest，并放入发送队列
        fetcher.initFetches(cluster);

        //步骤2：网络poll
        client.poll(timeout);

        //步骤3：取结果
        return fetcher.fetchedRecords();
    }
```

## offset初始化– 手动指定 vs. 自动指定
当consumer初次启动的时候，面临的一个首要问题就是：从offset为多少的位置开始消费。关于这个，有2种策略：

### 手动指定
调用seek(TopicPartition, offset)，然后开始poll

### 自动指定
poll之前，给集群发送请求，让集群告知客户端，当前该TopicPartition的offset是多少。这也就是上面的代码：
```
if (!subscriptions.hasAllFetchPositions())
    updateFetchPositions(this.subscriptions.missingFetchPositions());
```
下面看一下该函数的内部细节：
```
//遍历所有的TopicPartition，如果其状态hasValidPosition = false，说明此时客户端不知道其offset，需要向服务器请求
    public boolean hasAllFetchPositions() {
        for (TopicPartitionState state : assignment.values())
            if (!state.hasValidPosition)
                return false;
        return true;
    }

    private void updateFetchPositions(Set<TopicPartition> partitions) {
        coordinator.refreshCommittedOffsetsIfNeeded();
        fetcher.updateFetchPositions(partitions);
    }

//Coordinator
    public void refreshCommittedOffsetsIfNeeded() {
        if (subscriptions.refreshCommitsNeeded()) {
            Map<TopicPartition, OffsetAndMetadata> offsets = fetchCommittedOffsets(subscriptions.assignedPartitions());  //关键函数
            for (Map.Entry<TopicPartition, OffsetAndMetadata> entry : offsets.entrySet()) {
                TopicPartition tp = entry.getKey();
                // verify assignment is still active
                if (subscriptions.isAssigned(tp))
                    this.subscriptions.committed(tp, entry.getValue());
            }
            this.subscriptions.commitsRefreshed();
        }
    }

    public Map<TopicPartition, OffsetAndMetadata> fetchCommittedOffsets(Set<TopicPartition> partitions) {
        while (true) {
            ensureCoordinatorKnown();

            // contact coordinator to fetch committed offsets
            RequestFuture<Map<TopicPartition, OffsetAndMetadata>> future = sendOffsetFetchRequest(partitions);
            client.poll(future);

            if (future.succeeded())
                return future.value();

            if (!future.isRetriable())
                throw future.exception();

            time.sleep(retryBackoffMs);
        }
    }

    private RequestFuture<Map<TopicPartition, OffsetAndMetadata>> sendOffsetFetchRequest(Set<TopicPartition> partitions) {
        if (coordinatorUnknown())
            return RequestFuture.coordinatorNotAvailable();

        log.debug("Fetching committed offsets for partitions: {}",  partitions);
        // construct the request
        OffsetFetchRequest request = new OffsetFetchRequest(this.groupId, new ArrayList<TopicPartition>(partitions));

        // send the request with a callback
        return client.send(coordinator, ApiKeys.OFFSET_FETCH, request)
                .compose(new OffsetFetchResponseHandler());
    }
```
可以看到，上面关键是发了一个OffsetFetchRequest，并且是同步调用，直到获取到初始的offset，再开始接下来的poll

## Fetcher核心流程分析
通过上面的步骤，consumer的每个TopicPartition都有了初始的offset，接下来就可以进行不断循环取消息了，这也就是Fetch的过程：

### 步骤1：fetcher.initFetches(cluster)
在步骤1中，核心就是生成FetchRequest: 
假设一个consumer订阅了3个topic: t0, t1, t2，为其分配的partition分别是： 
t0: p0; 
t1: p1, p2; 
t2: p2

即总共4个TopicPartition，即t0p0, t0p1, t1p1, t2p2。这4个TopicPartition可能分布在2台机器n0, n1上面： 
n0: t0p0, t1p1 
n1: t0p1, t2p2

则会分别针对每台机器生成一个FetchRequest，即Map
```
public void initFetches(Cluster cluster) {
        for (Map.Entry<Node, FetchRequest> fetchEntry: createFetchRequests(cluster).entrySet()) {
            final FetchRequest fetch = fetchEntry.getValue();
            client.send(fetchEntry.getKey(), ApiKeys.FETCH, fetch)
                    .addListener(new RequestFutureListener<ClientResponse>() {
                        @Override
                        public void onSuccess(ClientResponse response) {
                            handleFetchResponse(response, fetch);
                        }

                        @Override
                        public void onFailure(RuntimeException e) {
                            log.debug("Fetch failed", e);
                        }
                    });
        }
    }

//关键函数：把所有属于同一个Node的TopicPartition放在一起，生成一个FetchRequest
    private Map<Node, FetchRequest> createFetchRequests(Cluster cluster) {
        // create the fetch info
        Map<Node, Map<TopicPartition, FetchRequest.PartitionData>> fetchable = new HashMap<>();
        for (TopicPartition partition : subscriptions.fetchablePartitions()) {
            Node node = cluster.leaderFor(partition);
            if (node == null) {
                metadata.requestUpdate();
            } else if (this.client.pendingRequestCount(node) == 0) {
                // if there is a leader and no in-flight requests, issue a new fetch
                Map<TopicPartition, FetchRequest.PartitionData> fetch = fetchable.get(node);
                if (fetch == null) {
                    fetch = new HashMap<>();
                    fetchable.put(node, fetch);
                }

                long position = this.subscriptions.position(partition);
                fetch.put(partition, new FetchRequest.PartitionData(position, this.fetchSize));
                log.trace("Added fetch request for partition {} at offset {}", partition, position);
            }
        }

        // create the fetches
        Map<Node, FetchRequest> requests = new HashMap<>();
        for (Map.Entry<Node, Map<TopicPartition, FetchRequest.PartitionData>> entry : fetchable.entrySet()) {
            Node node = entry.getKey();
            FetchRequest fetch = new FetchRequest(this.maxWaitMs, this.minBytes, entry.getValue());
            requests.put(node, fetch);
        }
        return requests;
    }
```
### 步骤2：poll
### 步骤3：fetcher.fetchedRecords()
这里要注意，在步骤1构造FetchRequest的时候，已经在其callback函数中处理了返回的Response，即把返回结果加入了Fetcher的成员变量records里面：
```
public class Fetcher<K, V> {
   ...
   //每个TopicPartition对应一个ConsumerRecordList + 一个fetchOffset
   private final List<PartitionRecords<K, V>> records;
   ...
}

private static class PartitionRecords<K, V> {
        public long fetchOffset;
        public TopicPartition partition;
        public List<ConsumerRecord<K, V>> records;

        public PartitionRecords(long fetchOffset, TopicPartition partition, List<ConsumerRecord<K, V>> records) {
            this.fetchOffset = fetchOffset;
            this.partition = partition;
            this.records = records;
        }
    }
```

这里的fetchedRecords，主要是返回records变量，同时把offset置到nextOffset.

## 手动消费确认 vs. 自动消费确认
在前面我们提到了，消费完消息之后，客户端需要向服务器发送消息确认，确认有2中策略：

### 手动消费确认
手动调用KafkaConsumer的2个函数：
```
public void commitSync() ;  //同步确认
public void commitAsync(OffsetCommitCallback callback); //异步确认
```
```
public void commitOffsetsSync(Map<TopicPartition, OffsetAndMetadata> offsets) {
        if (offsets.isEmpty())
            return;
        while (true) {
            ensureCoordinatorKnown();

            RequestFuture<Void> future = sendOffsetCommitRequest(offsets);    //发送offsetCommit请求
            client.poll(future); //同步调用

            if (future.succeeded())
                return;

            if (!future.isRetriable())
                throw future.exception();

            time.sleep(retryBackoffMs);
        }
    }

    public void commitOffsetsAsync(final Map<TopicPartition, OffsetAndMetadata> offsets, OffsetCommitCallback callback) {
        this.subscriptions.needRefreshCommits();
        RequestFuture<Void> future = sendOffsetCommitRequest(offsets);
        final OffsetCommitCallback cb = callback == null ? defaultOffsetCommitCallback : callback;   //异步
        future.addListener(new RequestFutureListener<Void>() {
            @Override
            public void onSuccess(Void value) {
                cb.onComplete(offsets, null);
            }

            @Override
            public void onFailure(RuntimeException e) {
                cb.onComplete(offsets, e);
            }
        });
    }
```
### 自动消费确认
客户端不做确认，由client内部，周期性的发送确认消息，类似HeartBeat，其实现机制也就是前面所讲的DelayedQueue + DelayedTask
```
private class AutoCommitTask implements DelayedTask {
        private final long interval;
        private boolean enabled = false;
        private boolean requestInFlight = false;

        public AutoCommitTask(long interval) {
            this.interval = interval;
        }

        public void enable() {
            if (!enabled) {

                client.unschedule(this);
                this.enabled = true;

                if (!requestInFlight) {
                    long now = time.milliseconds();
                    client.schedule(this, interval + now);
                }
            }
        }

        public void disable() {
            this.enabled = false;
            client.unschedule(this);
        }

        private void reschedule(long at) {
            if (enabled)
                client.schedule(this, at);
        }

        public void run(final long now) {
            if (!enabled)
                return;

            if (coordinatorUnknown()) {
                log.debug("Cannot auto-commit offsets now since the coordinator is unknown, will retry after backoff");
                client.schedule(this, now + retryBackoffMs);
                return;
            }

            requestInFlight = true;
            commitOffsetsAsync(subscriptions.allConsumed(), new OffsetCommitCallback() {
                @Override
                public void onComplete(Map<TopicPartition, OffsetAndMetadata> offsets, Exception exception) {
                    requestInFlight = false;
                    if (exception == null) {
                        reschedule(now + interval);  //在回调里面，再次放入AutoCommitTask
                    } else if (exception instanceof SendFailedException) {
                        log.debug("Failed to send automatic offset commit, will retry immediately");
                        reschedule(now);
                    } else {
                        log.warn("Auto offset commit failed: {}", exception.getMessage());
                        reschedule(now + interval);
                    }
                }
            });
        }
    }
```