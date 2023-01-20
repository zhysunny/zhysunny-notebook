# Hive编程指南

## Hive的基础操作
**Hive的一次性使用命令**

    [root@lvd121 ~]# hive -e "select * from test"
    OK
    hello world
    java python scala shell
    scala spark java
    hadoop hive spark
    oozie mysql
    Time taken: 3.314 seconds, Fetched: 5 row(s)

**静默模式，去掉OK和Time taken**

    [root@lvd121 ~]# hive -S -e "select * from test"
    hello world
    java python scala shell
    scala spark java
    hadoop hive spark
    oozie mysql

**将sql放在文件中，用hive执行sql文件（静默模式有效）**

    [root@lvd121 ~]# cat select_test.sql 
    select * from test
    [root@lvd121 ~]# hive -f select_test.sql
    OK
    hello world
    java python scala shell
    scala spark java
    hadoop hive spark
    oozie mysql
    Time taken: 3.314 seconds, Fetched: 5 row(s)

**在hive中执行shell命令**

前面需要!然后以分号结尾

    hive> !pwd;
    /root

**在hive中执行hadoop命令**
hadoop必须去掉，使用dfs不能使用fs

    hive> dfs -ls /user/hive;
    Found 1 items
    drwxrwxrwt   - hive hive          0 2019-05-27 18:37 /user/hive/warehouse


## 数据类型和文件格式
**基本数据类型**

|数据类型|长度|与java对比|
|---|---|---|
|tinyint|1byte有符号整数|byte|
|smalint|2byte有符号整数|short|
|int|4byte有符号整数|int|
|bigint|8byte有符号整数|long|
|boolean|布尔型|true/false|
|float|单精度浮点型|float|
|double|双精度浮点型|double|
|string|字符串，单双引号都可|String|
|timestamp|整数，浮点，字符串|java.sql.Timestamp|
|binary|字节数组||

**集合数据类型**

|数据类型|描述|
|---|---|
|struct|和c语言中的struct类似，可以通过点符号访问元素内容，例如.first,.last|
|map|键值对，如'first'->'john'，可以通过['first']访问|
|array|数组，通过索引访问，例如[0]|

**文本文件数据编码**

|分隔符|描述|
|---|---|
|\n|对于文本文件来说，每一行都是一条记录，因此换行符可以分割记录|
|^A(Ctrl+A)|用于分割字段(列)，可以使用八进制编码\001|
|^B|用于分割array或struct的元素，或map键值对，可以用八进制编码\002|
|^C|用于分割map键和值，可以用八进制编码\003|

    create table employee(
        name string,
        salary float,
        subordinates array<string>,
        deductions map<string,float>,
        arress struct<street:string,city:string,state:string,zip:int>
    )
    row format delimited
    fields terminated by '\001'
    collection items terminated by '\002'
    map keys terminated by '\003'
    lines terminated by '\n'
    stored as textfile;

## 数据定义

**hive的数据库**

    create database corpus; --创建数据库，数据库已存在报错
    create database if not exists corpus; --创建数据库，数据库已存在不会报错
    drop database corpus; --删除数据库，数据库不存在报错
    drop database if exists corpus; --删除数据库，数据库不存在不会报错
    drop database if exists corpus cascade; --默认有表的数据库不能删除，加上cascade关键字先删除表再删除数据库
    show databases; --展示所有数据库
    show databases like 'cor*'; --展示正则匹配的数据库
    set hive.cli.print.current.db=true; --显示当前所在的数据库名
    -- database 可以换成 schema

**hive的表**

    --建表语句
    create table if not exists employee(
        name string comment 'Employee name',
        salary float comment 'Employee salary',
        subordinates array<string> comment 'Names of subordinates',
        deductions map<string,float> comment 'Keys are deductions names,Values are percentages',
        arress struct<street:string,city:string,state:string,zip:int> comment 'Home address'
    )
    comment 'Employee information table' --表注释
    tblproperties ('creator'='me','created_at'='2019-06-04 15:02:00',...) --表属性
    location '/user/hive/warehouse/test.db/employee'; --表数据存储路径

    --复制表结构(不会复制数据)
    create table if not exists employee2 
    like employee;

    show tables in test; --展示test数据库中所有的表名
    show tables like 'emp*'; --展示正则匹配的表名(不能和in test组合使用)
    desc extended employee; --展示表employee的详细信息
    desc formatted employee; --展示表employee的详细信息(可读性比extended更强)
    desc employee.name; --展示name字段信息
    create external table...; --创建外部表，建议指定location路径，不指定默认路径和内部表一样

**hive的分区表**

    create table if not exists article_dt(
        sentence string
    )
    partitioned by(dt string)
    row format delimited fields terminated by '\n';
    --在hdfs表article_dt目录下生成'dt=字段值'的目录
    --在表结构中dt和字段没有区别，在实际数据文件不需要存储dt字段
    
    show partitions article_dt; --查看表article_dt的分区
    show partitions article_dt partition(dt=16); --查看表article_dt的某个分区

**hive的外部分区表**

    --外部分区表存在一个问题，假设表
    create external table if not exists logger(
        message string
    )
    partitioned by(year string,month string,day string)
    row format delimited fields terminated by '\n';
    --一般外部表并非load data加载数据，而是直接引用hdfs数据，假设数据目录格式定义为logger/2019/06/04,这时是读不到数据的
    --修改分区路径
    alter table logger add if not exists 
    partition(year=2019,month=06,day=04) location '/user/hive/warehouse/test.db/logger/2019/06/04';

    desc formatted logger partition(year=2019,month=06,day=04); --可以查看分区的具体目录

**修改表**

    -- 表重命名
    alter table test rename to test;
    -- 外部表增加新的分区
    alter table logger add if not exists 
    partition(year=2019,month=06,day=01) location '/user/hive/warehouse/test.db/logger/2019/06/01'
    partition(year=2019,month=06,day=02) location '/user/hive/warehouse/test.db/logger/2019/06/02'
    partition(year=2019,month=06,day=03) location '/user/hive/warehouse/test.db/logger/2019/06/03';
    -- 删除分区
    alter table logger drop if exists partition(year=2019,month=06,day=01);
    -- 修改列名，类型，注释，位置
    alter table test change column name sex int after age;
    -- 增加列
    alter table test add columns(
        name string,
        age int
    );
    -- 移除所有字段，并设置新的字段
    alter table test replace columns(
        name string,
        age int,
        messgae string
    );
    -- 增加或修改表属性，但不能删除
    alter table test set tblproperties(
        'note'='this is test'
    );
    -- 修改文件存储格式，可以设置分区文件存储格式
    alter table test set fileformat sequencefile;


## 数据操作

    -- 装载数据
    load data 