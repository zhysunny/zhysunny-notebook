## 准备

安装使用docker
版本：mysql:5.7
图形化工具：Navicat

## 基础

### select

常量、表达式、函数、别名，去重

* +号的作用
和java不一样，mysql的+号只能作为运算符
select 100+90;   190，运算符
select '100'+90;  190，字符串会尝试转数值再运算
select 'john'+90;  90，字符串转数值失败默认为0
select null+90;  null，有一个值为null，结果就是null，可以使用ifnull(column, 0)解决

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

