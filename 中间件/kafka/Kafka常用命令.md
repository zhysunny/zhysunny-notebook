1.启动kafka

    ./kafka-server-start.sh -daemon ../config/server.properties

2.创建topic

    ./kafka-topics.sh --create --zookeeper `hostname`:2181 --replication-factor 2 --partitions 2 --topic topicName
    
3.启动生产者

	./kafka-console-producer.sh --broker-list `hostname`:9092 --topic topicName

4.启动消费者

	./kafka-console-consumer.sh --zookeeper `hostname`:2181 --topic topicName --from-beginning
	
5.查看topic列表

	./kafka-topics.sh --list --zookeeper `hostname`:2181

6.查看topic详情

	./kafka-topics.sh --describe --zookeeper `hostname`:2181 --topic topicName

7.查看消费组列表

    ./kafka-consumer-groups.sh --list --zookeeper `hostname`:2181
    ./kafka-consumer-groups.sh --bootstrap-server `hostname`:9092 --new-consumer --list

8.查看消费组详情

    ./kafka-consumer-groups.sh --bootstrap-server `hostname`:9092 --new-consumer --describe --group groupName
	
9.删除topic
    
    ./kafka-topics.sh --delete --zookeeper `hostname`:2181 --topic topicName