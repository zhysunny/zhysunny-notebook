# Hive练习题

## 作业1 创建表并导入数据

    create database if not exists test;
    create table if not exists test.course(cid string, name string, tid string)row format delimited fields terminated by '\t' stored as textfile;
    create table if not exists test.score(sid string, cid string, score int)row format delimited fields terminated by '\t' stored as textfile;
    create table if not exists test.student(sid string, name string, birth string, gender int)row format delimited fields terminated by '\t' stored as textfile;
    create table if not exists test.teacher(tid string, name string)row format delimited fields terminated by '\t' stored as textfile;
    load data local inpath "${LOCAL_PATH}/data/hive/course.txt" into table test.course;
    load data local inpath "${LOCAL_PATH}/data/hive/score.txt" into table test.score;
    load data local inpath "${LOCAL_PATH}/data/hive/student.txt" into table test.student;
    load data local inpath "${LOCAL_PATH}/data/hive/teacher.txt" into table test.teacher;
    
## 作业2 统计每个学生的总分，并按照总分降序排序，显示学生ID，学生姓名，总分

    select sc.sid, st.name, sc.score 
    from (select sid, sum(score) score from test.score group by sid) sc
    join test.student st on sc.sid = st.sid
    order by sc.score desc
    limit 10;
    
## 作业3 计算每个学生的年龄，显示学生ID，姓名，生日，年龄，性别：0女 1男

    select sid, name, birth, 
    if(gender='0','女','男') gender,
    year(from_unixtime(unix_timestamp(),'yyyy-MM-dd HH:mm:ss')) - year(birth) as age 
    from test.student 
    order by age desc
    limit 10;

## 作业4 统计每个年龄每个性别的学生个数，显示年龄，女生个数，男生个数

    select age, 
    sum(case when gender=0 then 1 else 0 end) woman, 
    sum(case when gender=1 then 1 else 0 end) man
    from (select year(from_unixtime(unix_timestamp(),'yyyy-MM-dd HH:mm:ss')) - year(birth) as age,gender
    from test.student) t
    group by age
    order by age;

## 作业5 统计每个学生的总分，并按照总分降序排序，显示学生ID，学生姓名，各个科目成绩，总分，排名

    select t.*,st.name,
    t.chinese+t.math+t.english+t.political+t.history+t.geographic+t.physical+t.chemical+t.biological total,
    row_number() over(partition by 1) ranking
    from (select sc.sid,
    sum(case when co.name='语文' then sc.score end) as chinese,
    sum(case when co.name='数学' then sc.score end) as math,
    sum(case when co.name='英语' then sc.score end) as english,
    sum(case when co.name='政治' then sc.score end) as political,
    sum(case when co.name='历史' then sc.score end) as history,
    sum(case when co.name='地理' then sc.score end) as geographic,
    sum(case when co.name='物理' then sc.score end) as physical,
    sum(case when co.name='化学' then sc.score end) as chemical,
    sum(case when co.name='生物' then sc.score end) as biological
    from test.score sc join test.course co on sc.cid = co.cid
    group by sc.sid) t join test.student st on t.sid = st.sid
    order by total desc
    limit 10;
