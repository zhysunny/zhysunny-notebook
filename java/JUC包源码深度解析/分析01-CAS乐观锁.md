# 分析01-CAS乐观锁

## 乐观锁思想
问题的提出：
```
当多个线程或客户端并发修改同1份数据时，不加锁，如何实现互斥访问？
```
乐观锁基本思路：
```
给数据本身加一个版本号字段，读取和写入时都不加锁。数据读出来的时候，此时版本号为v1，修改之后，写回去的时候，做如下比较：如果v1不等于数据当前的版本号，则说明在此期间，数据被其他线程或客户端修改过了，则此次提交失败；如果v1等于数据当前的版本号，则说明在此期间，没有其他线程或客户端修改过数据，则此次提交成功，同时把数据的版本号置为v1+1。
```
乐观锁，有2个重要特点：
```
1.比较和修改数据，必须是原子操作，这也就是著名的Compare And Set(CAS)。
2.CAS可能失败，此时需要把数据重新读取出来，重新修改，重新比较版本号和CAS，直到CAS成功。这也就是所谓的Conditional Update，循环重试。
```
## 乐观锁的几种具体实现
乐观锁的思想，无论是在Java多线程编程（当然也包括其他语言），还是Mysql数据库操作中（当然也包含其他Nosql数据库），都有应用。下面介绍几种常见应用： AtomicInteger, AtomicStampedReference, Mysql乐视锁。

## AtomicInteger/CAS
以下代码展示了JUC包的AtomicInteger的++, - - 操作的乐视锁实现
```
    public final int getAndIncrement() {
        for (;;) { //失败，循环重试
            int current = get();      //读取值
            int next = current + 1;   //修改值
            if (compareAndSet(current, next))  //比较并且赋值
                return current;
        }
    }

    public final int getAndDecrement() {
        for (;;) {
            int current = get();
            int next = current - 1;
            if (compareAndSet(current, next))
                return current;
        }
    }
    
    public final boolean compareAndSet(int expect, int update) {
    //调用native代码，实现一个CAS原子操作
	return unsafe.compareAndSwapInt(this, valueOffset, expect, update); 
    }
```
关键点：
* 在以上代码中，可以看到compareAndSet(int expect, int update)的第1个参数，传进去的并不是版本号，而是数据的旧值。也就是说，它认为，只要数据的旧值expect = 数据当前的值，则说明在此期间没有其他线程修改过此数据，则把数据修改为新值update。
* 这种比较值，而不是比较版本号的做法，会产生经典的ABA问题。而这，也正是AtomicStampedReference要解决的。
## ABA问题/AtomicStampedReference
ABA问题：
```
在线程1改数据期间，线程2把数据改为A，再改为B，再改回到A。这个时候，线程1做CAS的时候，如果只是比较值，则它会认为数据在此期间没有被改动过，而实际上数据已被线程2改动过3次。
```
要解决此问题，就不能基于值的比较做CAS，而要基于版本号的比较来做，因为版本号是不断递增的，每修改1次，版本号就增大1次。这正是AtomicStampedReference。

以下代码展示了AtomicStampedReference中的CAS:
```
    public boolean compareAndSet(V      expectedReference,  //旧值
                                 V      newReference,   //新值
                                 int    expectedStamp,   //旧版本号
                                 int    newStamp     //新版本号
 {
        ReferenceIntegerPair<V> current = atomicRef.get();
        return  expectedReference == current.reference &&
            expectedStamp == current.integer &&
            ((newReference == current.reference &&
              newStamp == current.integer) ||
             atomicRef.compareAndSet(current,
                                     new ReferenceIntegerPair<V>(newReference,
                                                              newStamp)));
    }


    private static class ReferenceIntegerPair<T> {
        private final T reference;    //值
        private final int integer;    //版本号
        ReferenceIntegerPair(T r, int i) {
            reference = r; integer = i;
        }
    }
```
关键点：
–上面的atomicRef.compareAndSet（…）的第一个参数，传入的是一个ReferenceIntegerPair对象，它里面包含了2个字段：值 + 版本号。这也就意味着，它同时比较了值和版本号。
– 值不等，则肯定被其他线程改过了，不用再比较版本号，cas提交失败；
值相等，再比较版本号，如果版本号也相等，则说明真的没有被改过，cas提交成功；
值相等，版本号不等，则就是出现了ABA，cas提交失败。

下面看一下AtomicStampedReference的源码：
```
public class AtomicStampedReference<V>  {  
    private static class ReferenceIntegerPair<T> {  
        private final T reference;  
        private final int integer;  
        ReferenceIntegerPair(T r, int i) {  
            reference = r; integer = i;  
        }  
    }  
   
   //从代码可以看出，AtomicStampedReference的本质就是AtomicReference，只是在每个对象上，加锁一个integer版本号，构成一个Pair对象
    private final AtomicReference<ReferenceIntegerPair<V>>  atomicRef;  
 
    public AtomicStampedReference(V initialRef, int initialStamp) {  
        atomicRef = new AtomicReference<ReferenceIntegerPair<V>>  
            (new ReferenceIntegerPair<V>(initialRef, initialStamp));  
    }  
```
类似的还有一个AtomicMarkableReference，绑的不是integer，而是一个boolean类型的标志位。
```
public class AtomicMarkableReference<V>  {  
    private static class ReferenceBooleanPair<T> {  
        private final T reference;  
        private final boolean bit;  
        ReferenceBooleanPair(T r, boolean i) {  
            reference = r; bit = i;  
        }  
    }  
    private final AtomicReference<ReferenceBooleanPair<V>>  atomicRef;  
 
    public AtomicMarkableReference(V initialRef, boolean initialMark) {  
        atomicRef = new AtomicReference<ReferenceBooleanPair<V>> (new ReferenceBooleanPair<V>(initialRef, initialMark));  
    }  
```
## Mysql乐视锁
问题的提出：
```
有一张User表，里面有个balance字段，多个事务，并发修改此值，如何保证不会出现"丢失更新"？
|id|banlance|…其他字段|
|1 | 100 | … |
|2 | 150 | … |
```
## 悲观锁伪码实现
```
事务1
begin_transaction

int b = select balance from User where id = 1 for update;  //加悲观锁

b = b + 50;

update User set balance = b where id = 1;

end_transaction

事务2

begin_transaction

int b = select balance from User where id = 1 for update;  //加悲观锁

b = b - 50;

update User set balance = b where id = 1;

end_transaction
```

### 乐观锁伪码实现1
首先，需要给表加上一个version字段
```
|id|banlance|…其他字段| version |
|1 | 100 | … | 0 |
|2 | 150 | … | 0 |
```
```
事务1
begin_transaction

while(!result)  //CAS不成功，把数据重新读出来，修改之后，重新CAS
{
	int b, v = select balance, version from User where id = 1 ;  //不加锁

	b = b + 50;

	result = update User set balance = b, version = version + 1 where id = 1 and version = v;  //CAS，每次修改成功，version+1
}

end_transaction

事务2

begin_transaction

while(!result)
{
	int b, v = select balance, version from User where id = 1 ;  //不加锁

	b = b - 50;

	result = update User set balance = b, version = version + 1 where id = 1 and version = v;  //CAS，每次修改成功，version+1
}

end_transaction
```

### 乐观锁伪码实现2
不加version，加一个时间戳timestamp字段
```
|id|banlance|…其他字段| timestamp |
|1 | 100 | … | |
|2 | 150 | … | |
```
```
事务1
begin_transaction

while(!result)  //CAS不成功，把数据重新读出来，修改之后，重新CAS
{
	int b = select balance from User where id = 1 ;  //不加锁

    b = b + 50;
	date t = now();

	result = update User set balance = b, timestamp = now() where id = 1 and timestamp <= t;  //CAS，每次修改成功，timestamep设为当前时间
}

end_transaction

事务2

begin_transaction

while(!result)  //CAS不成功，把数据重新读出来，修改之后，重新CAS
{
	int b = select balance from User where id = 1 ;  //不加锁

    b = b - 50;
	date t = now();

	result = update User set balance = b, timestamp = now() where id = 1 and timestamp <= t;  //CAS，每次修改成功，timestamep设为当前时间
}

end_transaction
```
备注：
在实际业务中，可能不会像这样死循环重试下去，而会设置一个重试次数。超过重试次数，返回失败，让上层业务去重新处理。

## Mysql MVCC

* 很多人会有个误解，以为Mysql MVCC就是Mysql的乐观锁。但从上面可以看出，Mysql乐观锁，完全可以在应用层面来实现。而MVCC是Mysql内部，用来提高并发的一种手段。
* 这种手段，个人认为，本质上其实是把读写锁。也就是：读的时候，不加锁，也就普通的select，不加for update；写的时候，先把当前数据拷贝一份（也就是多版本的意思），然后加锁，写入。这有点类似ConcurrentHashMap的读不加锁，写加锁。关于MVCC，ConcurrentHashMap，将在后续章节讲述。

##总结
```
**乐观锁其实就是不加锁，用CAS + 循环重试，实现多个线程/多个客户端，并发修改数据的问题。**
```
