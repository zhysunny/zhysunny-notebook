### 业务一：对于未知的数据入库，如果doc存在则修改，如果不存在则添加

IndexRequest：
    doc不存在：新增doc
    doc存在：删除原doc，新增新doc
    
UpdateRequest：
    doc不存在：报错
    doc存在：只修改不同值的字段
    
UpdateRequest：追加upsert(IndexRequest)
    doc不存在：新增doc
    doc存在：只修改不同值的字段