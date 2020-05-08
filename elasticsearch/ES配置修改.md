# 常用的ES配置修改

1.默认from+size不能大于10000

curl -XPUT http://${host}:9200/_settings -d '{"index":{"max_result_window":100000}}'

2.当es有个节点退出时，副本重建的间隔时间，默认1m

curl -XPUT http://${host}:9200/_all/_settings -d '{"settings":{"index.unassigned.node_left.delayed_timeout":"5m"}}'

3.修改索引副本

curl -XPUT http://${host}:9200/${index}/_settings -d '{"index": {"number_of_replicas": "0"}}'