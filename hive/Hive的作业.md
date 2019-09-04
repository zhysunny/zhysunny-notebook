# Hive的作业

## 作业1
**创建表order_products_prior，数据为order_products_prior.csv，创建表orders，数据为orders.csv**

    --order_id 订单ID
    --order_products_prior 订单和产品信息表
    --add_to_cart_order 订单中商品排序
    --reordered 是否重复购买过，以前买过为1，没买过为0

    create table order_products_prior(
    order_id string,
    product_id string,
    add_to_cart_order string,
    reordered string
    )row format delimited fields terminated by ',';
    load data local inpath '/opt/data/test/order_products__prior.csv' 
    into table order_products_prior;

    --order_id 订单ID
    --user_id 用户ID
    --eval_set 标识训练集和测试集
    --order_number 购买订单的顺序
    --order_dow 一周中星期几购买，相当于day of week
    --order_hour_of_day 一天中什么时间购买
    --days_since_prior_order 下一个订单距离上一个订单多少天

    create table orders(
    order_id string,
    user_id string,
    eval_set string,
    order_number string,
    order_dow string,
    order_hour_of_day string,
    days_since_prior_order string
    )row format delimited fields terminated by ',';
    load data local inpath '/opt/data/test/orders.csv' 
    into table orders;

## 作业2
**每个用户有多少订单**

    select user_id,count(*) order_cnt
    from orders
    group by user_id;

## 作业3
**统计每个用户购买过多少个商品**

    --先统计每个订单用多少商品
    select order_id,count(*) product_cnt 
    from order_products_prior 
    group by order_id;

    --通过order_id关联orders表，再求和
    select t1.user_id,sum(t2.product_cnt) product_sum 
    from orders t1 join (
    select order_id,count(*) product_cnt from order_products_prior group by order_id
    ) t2  on t1.order_id=t2.order_id 
    group by t1.user_id;

    --一次join统计
    select t1.user_id,count(t2.product_id) prod_cnt
    from orders t1 join order_products_prior t2
    on t1.order_id=t2.order_id
    group by t1.user_id;

## 作业4
**每个用户平均每个订单是多少商品**

    select t1.user_id,avg(t2.product_cnt) product_avg 
    from orders t1 join (
    select order_id,count(*) product_cnt from order_products_prior group by order_id
    ) t2  on t1.order_id=t2.order_id 
    group by t1.user_id;

### 作业5
**每个用户在一周中的购买订单的分布**

    select user_id,
    sum(case when order_dow='0' then 1 else 0 end) as dow_0,
    sum(case when order_dow='1' then 1 else 0 end) as dow_1,
    sum(case when order_dow='2' then 1 else 0 end) as dow_2,
    sum(case when order_dow='3' then 1 else 0 end) as dow_3,
    sum(case when order_dow='4' then 1 else 0 end) as dow_4,
    sum(case when order_dow='5' then 1 else 0 end) as dow_5,
    sum(case when order_dow='6' then 1 else 0 end) as dow_6
    from orders
    group by user_id;

    --case when...end 相当于if
    --注意结尾的end

## 作业6
**求每个用户平均每个购买天中购买的商品数 【把days_since_prior_order当做一个月中购买的天】**

    --求每个订单有多少商品
    --按照用户和购买天分组求和商品数
    --按照用户分组求商品数的平均数
    select t.user_id,avg(t.product_sum) product_avg
    from (
    select t1.user_id,t1.days_since_prior_order,sum(product_cnt) product_sum
    from orders t1 join (
    select order_id,count(*) product_cnt
    from order_products_prior
    group by order_id
    ) t2 on t1.order_id=t2.order_id
    group by t1.user_id,t1.days_since_prior_order
    ) t group by t.user_id;

    select user_id,avg(prod_count) prod_avg
    from (
    select t1.user_id,t1.days_since_prior_order,count(t2.product_id) prod_count
    from orders t1 join order_products_prior t2
    on t1.order_id=t2.order_id
    group by t1.user_id,t1.days_since_prior_order
    ) t group by user_id;

    --求每个订单有多少商品
    --按照用户分组求商品数的平均数
    select t1.user_id,sum(product_cnt)/count(distinct days_since_prior_order) product_avg
    from orders t1 join (
    select order_id,count(*) product_cnt
    from order_products_prior
    group by order_id
    ) t2 on t1.order_id=t2.order_id
    group by t1.user_id;

## 作业6
**每个用户最喜爱购买的三个product是什么，最终表结构可以是3个列，或者一个字符串**

    --关联两张表查询每个用户每个商品购买次数
    --对user_id进行partition，对product_cnt降序，生成序号row_num
    --求序号row_num<=3的记录
    select user_id,product_id,product_cnt,row_num
    from (
    select t.user_id,t.product_id,t.product_cnt,
    row_number() over(partition by t.user_id order by t.product_cnt desc) row_num
    from (
        select t2.user_id,t1.product_id,count(*) product_cnt
        from order_products_prior t1 join orders t2 
        on t1.order_id=t2.order_id
        group by t2.user_id,t1.product_id
        ) t
    ) tt
    where tt.row_num<=3;

    --关联两张表查询每个用户每个商品购买次数
    --对user_id进行partition，对product_cnt降序，生成序号row_num
    --collect_list分组合并字段值，concat_ws拼接字符串
    select user_id,collect_list(concat_ws('_',product_id,cast(product_cnt as string),cast(row_num as string))) top3
    from (
    select t.user_id,t.product_id,t.product_cnt,
    row_number() over(partition by t.user_id order by t.product_cnt desc) row_num
    from (
        select t2.user_id,t1.product_id,count(*) product_cnt
        from order_products_prior t1 join orders t2 
        on t1.order_id=t2.order_id
        group by t2.user_id,t1.product_id
        ) t
    ) tt
    where tt.row_num<=3
    group by user_id;

## 作业7
**对每个用户最喜爱购买的三个product的改编，每个用户最喜爱的top10%的商品**

1.如果一个用户购买一共购买了10个，返回top1，购买了20个返回top2

2.如果一个用户购买了3个，3*10%=0.3 返回top1，也就是不够的至少一个
    

    --查询每个用户购买的每个商品的数量
    --按照用户分组，每个商品数量降序排序，同时获得top10%的商品数
    select user_id,collect_list(concat_ws('_',product_id,cast(prod_cnt as string),cast(row_num as string))) top_10_percent
    from (
        select t.user_id,t.product_id,t.prod_cnt,
        row_number() over(partition by t.user_id order by t.prod_cnt desc) as row_num,
        ceil(cast(count(product_id) over(partition by user_id) as double)*0.1) top_num
        from (
            select t1.user_id,t2.product_id,count(*) prod_cnt
            from orders t1 join order_products_prior t2
            on t1.order_id=t2.order_id
            group by t1.user_id,t2.product_id
        ) t
    ) tt
    where row_num<=top_num
    group by user_id;

## 作业8
**建分区表，orders表按照order_dow建立分区表order_part，然后从hive查询orders动态插入orders_part表中**

    create table orders_part(
    order_id string,
    user_id string,
    eval_set string,
    order_number string,
    order_hour_of_day string,
    days_since_prior_order string
    )partitioned by (order_dow string)
    row format delimited fields terminated by ',';

    --手动
    insert overwrite table orders_part partition (order_dow='0') 
    select order_id,user_id,eval_set,order_number,order_hour_of_day,days_since_prior_order
    from orders where order_dow='0';
    ......

    --全部导入，必须设置参数
    set hive.exec.dynamic.partition.mode=nonstrict; --无限制模式
    insert overwrite table orders_part partition (order_dow) 
    select order_id,user_id,eval_set,order_number,order_hour_of_day,days_since_prior_order,order_dow from orders;

## 作业9
**统计商品的销量(pv)，购买的用户数(uv)，reordered数，在同一个sql中展示出来**

即输出形式：

|商品id|商品销量|购买用户数|reorder数|
|---|---|---|---|
|product_id|product_pv|product_uv|reorder_cnt|

注意这边的**reordered**在prior表中，表示对这个商品是否被再次购买，是描述商品的。

    select t2.product_id,
    count(1) product_pv,
    count(distinct t1.user_id) product_uv,
    sum(cast(t2.reordered as int)) reorder_cnt
    from orders t1 join order_products_prior t2
    on t1.order_id=t2.order_id
    group by product_id;

## 作业10
1.用allfiles.txt文件建hive表

|句子|新闻类别标签|
|---|---|
|sentences|label|

2.用replace将文本中的空格去掉
3.用python jieba udf对句子进行切词，以空格分割
4.用hive sql统计wordcount

    create table allfiles(
    sentences string,
    label string
    )row format delimited fields terminated by '##@@##';

    load data local inpath '/opt/data/badou/allfiles.txt'
    into table allfiles;

    select regexp_replace(sentences,' ','') senteces from allfiles;

    create table allfiles_noseg(
    sentences string,
    label string
    );
    insert overwrite table allfiles_noseg select regexp_replace(sentences,' ','') senteces,label from allfiles;

    add file /opt/hive/jieba_udf.py;
    select transform(sentences) using 'python3 jieba_udf.py' as (seg) from allfiles_noseg

    --split将字段值分割成数组
    --explode将数组的每个元素展开成一条记录
    select word,count(word)
    from (
    select explode(split(sentences,' ')) word from allfiles
    ) t
    group by word;

## 作业11
**每个用户购买的product商品去重后的集合数据(用字符串表示，以逗号分割)**

    select user_id,
    concat_ws(',',collect_set(product_id)) product_set
    from orders t1 join order_products_prior t2
    on t1.order_id=t2.order_id
    group by user_id;