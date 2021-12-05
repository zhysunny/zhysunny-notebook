## mysql架构

* 连接层
* 服务层：SQL接口，解析，优化器，缓存
* 引擎层：InnoDB、MyISAM
* 存储层

|对比项|MyISAM|InnoDB|
|---|---|---|
|主外键|不支持|支持|
|事务|不支持|支持|
|行表锁|表锁，操作一条记录也会锁表|行锁，操作一条记录不对其他行影响|
|缓存|只缓存索引，不缓存真实数据|既缓存索引，也缓存真实数据，内存影响性能|
|表空间|小|大|
|关注点|性能|事务|
|默认安装|Y|Y|

## SQL解析器读取顺序

from > on > join > where > group by > having > select > distinct > order by > limit

## 7种join

* 左连接（A+AB的交集）：select * from A left join B on A.key = B.key
* 右连接（B+AB的交集）：select * from A right join B on A.key = B.key
* 内连接（AB的交集）：select * from A inner join B on A.key = B.key
* （A-AB的交集）：select * from A left join B on A.key = B.key where B.key is null
* （B-AB的交集）：select * from A right join B on A.key = B.key where A.key is null

oracle
* 全连接（A+B）：select * from A full outer join B on A.key = B.key
* （A+B-AB的交集）：select * from A full outer join B on A.key = B.key where A.key is null or B.key is null

mysql
* 全连接（A+B）：select * from A left join B on A.key = B.key union select * from A right join B on A.key = B.key
* （A+B-AB的交集）：select * from A left join B on A.key = B.key where B.key is null union select * from A right join B on A.key = B.key where A.key is null

## 建索引条件

* 适合建索引
    * 主键自动唯一索引
    * 频繁作为查询条件
    * 关联字段，外键
    * 单值/组合索引，高并发适合组合索引
    * 排序字段
    * 统计或者分组字段，分组必排序
* 不适合建索引
    * 频繁更新的字段，经常增删改的表
    * where条件用不到的字段
    * 表记录太少
    * 数据重复且分布平均的字段，distinct/count越接近1，索引提升的效率越高
    
## EXPLAIN介绍

SQL样例：  
EXPLAIN select departments.dept_no,departments.dept_name 
from departments 
LEFT JOIN dept_emp on departments.dept_no = dept_emp.dept_no

结果
|id|select_type|table      |type |possible_keys|key      |key_len|ref                          |rows |filtered|extra|
|1 |SIMPLE     |departments|index|             |dept_name|162    |                             |9    |100     |Using index|
|1 |SIMPLE     |dept_emp   |ref  |dept_no      |dept_no  |16     |employees.departments.dept_no|41392|100     |Using index|

* id：
    * id相同，加载顺序由上到下
    * id不同，id值越大，加载优先级越高
    * id有相同有不同，id值越大，优先级越高，其次相同的id加载顺序由上到下
* select_type：
    * SIMPLE：简单查询，没有union和子查询，可以有join
    * PRIMARY：有子查询，最外层的表被标记
    * SUBQUERY：子查询（select和where）
    * DERIVED：衍生表（from）
    * UNION：union后的表被标记；union后的from包含子查询，外层标记为DERIVED
    * UNION RESULT：从union表获取的select结果
* type(访问类型排列)：system > const > eq_ref > ref > range > index > ALL
    * system: 表中只有一条记录
    * const: 通过索引一次就能找到，const用于比较主键或者unique索引，因为只匹配一条记录
    * eq_ref: 唯一索引扫描，一一对应，常用于主键关联查询
    * ref: 非唯一索引扫描，返回单个值的所有行
    * range: 根据索引做范围查询
    * index: 全索引扫描
    * ALL: 全表扫描
* possible_keys：显示表中当前的主键或者索引字段，查询未必使用到(实际性能优化用处不大)
* key：查询实际使用到的索引或者主键，对于覆盖索引，该索引仅存在key列表中
* key_len：索引字段最大可能的长度，不是实际长度，即key_len来源于表字段定义，数字越小越好
* ref：显示索引的那一列被使用，尽可能是常量
* rows：根据表统计信息及索引选用情况，大致估算查询结果需要读取的行数，越少越好
* extra：拓展字段
    * Using filesort：mysql对数据使用外部的索引排序，不是表中索引，mysql无法使用索引的排序称为文件排序
    * Using temporary：使用临时表保存中间结果，mysql对查询结果排序使用临时表，常见于order by和group by
    * Using index：相应select操作使用了覆盖索引，避免表数据读取；如果有Using where，表明索引被用来执行索引键值的查找，反之索引用来读取而非查找
    * Using where：使用了where语句
    * Using join buffer：使用了连接缓存
    * impossible where：无效的where，where的值总是false
    * select tables optimized away：没有group by，基于索引优化max/min
    * distinct：优化distinct，找到第一个值后不会再找相同的值

## 索引优化总结

* 组合索引中，如果按索引范围查找，后面的索引会失效，这种场景下范围查询的字段不建议创建索引