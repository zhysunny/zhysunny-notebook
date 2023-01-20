## 准备

安装使用docker
版本：mysql:5.7
图形化工具：Navicat

## 基础

### select

常量、表达式、函数、别名，去重

#### +号的作用
* 和java不一样，mysql的+号只能作为运算符
* select 100+90;   190，运算符
* select '100'+90;  190，字符串会尝试转数值再运算
* select 'john'+90;  90，字符串转数值失败默认为0
* **select null+90;  null，有一个值为null，结果就是null，可以使用ifnull(column, 0)解决**

### where

条件运算符：>,<,==,!=,<>,>=,<=
    补充：<=>  安全等于
逻辑运算符：&&,||,!,and,or,not
模糊查询：like,between... and,in,is null

### order by
desc，asc
支持单个字段、多个字段、表达式、函数、别名

### group by
必须和分组函数一起使用，例如count,sum,max,min等

## 函数

### 单行函数
length：字节长度，需要注意字符编码，utf8汉字为三个字节
concat：字符拼接
upper，lower：大小写转换
substr，substring：注意索引从1开始，substr(str,start),substr(str,start,length)
instr：类似java的indexOf，索引从1开始
trim：默认去掉左右空格，trim('a' from str),去掉左右的a字符
lpad，rpad：左右填充，lpad(str,length,str2),当str长度小于length，左边填充str2直到长度为length，当str长度大于length，取str前length的字符
replace：全部替换，replace(str,source,target)

round：四舍五入，round(float)，round(float, num)
ceil：向上取整，返回>=该值的最小整数
floor：向下取整，返回<=该值的最大整数
truncate：截断，保留小数点位数，truncate(float, num)，不做四舍五入
mod：取模

now：当前时间，标准格式，yyyy-MM-dd HH:mm:ss
curdate：当前日期，yyyy-MM-dd
curtime：当前时间，HH:mm:ss
year,month,day,hour,minute,sencond：取日期中的部分
monthname：英文月份
str_to_date：字符串转日期
date_format：日期转字符串
datediff：计算日期相差多少天

|格式符|功能|
|---|---|
|%Y|四位年|
|%y|两位年|
|%m|两位月|
|%c|一位月|
|%d|两位日|
|%H|24小时制|
|%h|12小时制|
|%i|分钟|
|%s|秒|

version：mysql版本
database：当前数据库
user：当前用户

if：if(conditions,expr1,expr2)
case... when：类似java的switch... case

case expr
when 常量1或条件1 then expr1;
when 常量2或条件2 then expr2;
when 常量3或条件3 then expr3;
else expr3;
end

### 分组函数

常见：sum、avg、max、min、count，忽略null值
分组前条件筛选使用where，分组后条件筛选使用having，优先使用分组前
group by支持单个字段、多个字段、表达式、函数、别名

### 事务

* 事务并发的问题：脏读，不可重复读，幻读
* 事务隔离级别：
* 事务回滚：了解savepoint

### 视图

了解视图

### 存储过程

自定义变量
set @name = 'aaa';
set @age := 20;
select @sex := 0;

select @name;
select @age;
select @sex;

局部变量，作用于begin end中间，一般用于存储过程
DECLARE m INT DEFAULT 1;
DECLARE n INT DEFAULT 2;
DECLARE sum INT;
set sum = m + n
select sum;

select 值 into 变量名 from 表

创建存储过程
CREATE PROCEDURE 存储过程名(参数列表)
BEGIN
    存储过程体
END

参数列表包含：参数模式 参数名 参数类型
参数模式
in:参数作为输入
out:参数作为输出
inout:参数既可以作为输入，也可以作为输出

### 函数

CREATE FUNCTION 函数名(参数列表) RETURNS 返回类型
BEGIN
		函数体
END

参数列表包含：参数名 参数类型

### 流程控制

if：if(conditions,expr1,expr2)

case (表达式)?
when 条件1 then 值1
when 条件2 then 值2
when 条件3 then 值3
else 值4
end;

只能在 begin end中
case (表达式)?
when 条件1 then 语句1;
when 条件2 then 语句2;
when 条件3 then 语句3;
else 语句4;
end case;

只能在 begin end中
if 条件1 then 语句1;
elseif 条件2 then 语句2;
else 语句3;
end if;

循环语句
while、loop、repeat
iterate: 类似于continue
leave: 类似于break

while 条件 do
    循环体
end while;

iterate和leave需要加标签的循环语句
标签名: while 条件 do
    循环体
end while 标签名;

模拟死循环
loop
    循环体
end loop;

repeat
    循环体
until 结束循环的条件
end repeat;