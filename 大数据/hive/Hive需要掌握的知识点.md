# Hive需要掌握的知识点

### 理论点
* hive的安装部署以及常见问题解决
* hive的原理
    * hive的概念
    * hive与传统数据库的区别
    * hive sql转换过程
    * hive的执行过程
* hive的内部表和外部表的区别
* hive的分区
* hive的分桶    
* hive的优化
    * map的优化
    * reduce的优化
    * 数据倾斜问题

### 实战点

* 建库建表
* 行分隔符、列分隔符
* 分区分桶、修改分区存储路径
* 内部表外部表
* 数据的导入
* 常用的hive优化配置项
    
### 深入理解

* hive join操作的优化
* hive的函数


    显示hive下内置所有函数
    show functions;
    显示 add_months 函数用法
    desc function extended add_months;
        
* hive UDF、UDTF、UDAF
* 数仓血缘分析
* 底层实现原理
