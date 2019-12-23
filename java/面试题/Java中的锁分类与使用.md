# Java中的锁分类与使用

## Java锁的种类

* 乐观锁/悲观锁
* 独享锁/共享锁
* 互斥锁/读写锁
* 可重入锁
* 公平锁/非公平锁
* 分段锁
* 偏向锁/轻量级锁/重量级锁
* 自旋锁

以上是一些锁的名词，这些分类并不是全是指锁的状态，有的指锁的特性，有的指锁的设计，下面总结的内容是对每个锁的名词进行一定的解释。

### 乐观锁/悲观锁

乐观锁：顾名思义，就是很乐观，每次去拿数据的时候都认为别人不会修改，所以不会上锁，但是在更新的时候会判断一下在此期间别人有没有去更新这个数据，可以使用版本号等机制。乐观锁适用于多读的应用类型，这样可以提高吞吐量，在Java中java.util.concurrent.atomic包下面的原子变量类就是使用了乐观锁的一种实现方式CAS(Compare and Swap 比较并交换)实现的。

悲观锁：总是假设最坏的情况，每次去拿数据的时候都认为别人会修改，所以每次在拿数据的时候都会上锁，这样别人想拿这个数据就会阻塞直到它拿到锁。比如Java里面的同步原语synchronized关键字的实现就是悲观锁。

悲观锁适合写操作非常多的场景，乐观锁适合读操作非常多的场景，不加锁会带来大量的性能提升。

悲观锁在Java中的使用，就是利用各种锁。

乐观锁在Java中的使用，是无锁编程，常常采用的是CAS算法，典型的例子就是原子类，通过CAS自旋实现原子操作的更新。

#### 乐观锁

* 数据库

实现数据版本一般有两种，第一种是使用版本号，第二种是使用时间戳。以版本号方式为例。

版本号方式：一般是在数据表中加上一个数据版本号version字段，表示数据被修改的次数，当数据被修改时，version值会加一。当线程A要更新数据值时，在读取数据的同时也会读取version值，在提交更新时，若刚才读取到的version值为当前数据库中的version值相等时才更新，否则重试更新操作，直到更新成功。

```
update table set xxx=#{xxx}, version=version+1 where id=#{id} and version=#{version};
```

* CAS操作

CAS（Compare and Swap 比较并交换），当多个线程尝试使用CAS同时更新同一个变量时，只有其中一个线程能更新变量的值，而其它线程都失败，失败的线程并不会被挂起，而是被告知这次竞争中失败，并可以再次尝试。

CAS操作中包含三个操作数——需要读写的内存位置(V)、进行比较的预期原值(A)和拟写入的新值(B)。如果内存位置V的值与预期原值A相匹配，那么处理器会自动将该位置值更新为新值B，否则处理器不做任何操作。

#### 悲观锁

悲观锁认为对于同一个数据的并发操作，一定会发生修改的，哪怕没有修改，也会认为修改。因此对于同一份数据的并发操作，悲观锁采取加锁的形式。悲观的认为，不加锁并发操作一定会出问题。

在对任意记录进行修改前，先尝试为该记录加上排他锁（exclusive locking）。

如果加锁失败，说明该记录正在被修改，那么当前查询可能要等待或者抛出异常。具体响应方式由开发者根据实际需要决定。

如果成功加锁，那么就可以对记录做修改，事务完成后就会解锁了。

期间如果有其他对该记录做修改或加排他锁的操作，都会等待我们解锁或直接抛出异常。

### 独享锁/共享锁

独享锁是指该锁一次只能被一个线程所持有。

共享锁是指该锁可被多个线程所持有。

对于Java ReentrantLock而言，其是独享锁。但是对于Lock的另一个实现类ReadWriteLock，其读锁是共享锁，其写锁是独享锁。

读锁的共享锁可保证并发读是非常高效的，读写，写读，写写的过程是互斥的。

独享锁与共享锁也是通过AQS来实现的，通过实现不同的方法，来实现独享或者共享。

对于Synchronized而言，当然是独享锁。

### 互斥锁/读写锁

上面讲的独享锁/共享锁就是一种广义的说法，互斥锁/读写锁就是具体的实现。

互斥锁在Java中的具体实现就是ReentrantLock。

读写锁在Java中的具体实现就是ReadWriteLock。

### 可重入锁

可重入锁又名递归锁，是指在同一个线程在外层方法获取锁的时候，在进入内层方法会自动获取锁。说的有点抽象，下面会有一个代码的示例。

对于Java ReetrantLock而言，从名字就可以看出是一个重入锁，其名字是Re entrant Lock 重新进入锁。

对于Synchronized而言，也是一个可重入锁。可重入锁的一个好处是可一定程度避免死锁。

```
synchronized void setA() throws Exception{
　　Thread.sleep(1000);
　　setB();
}

synchronized void setB() throws Exception{
　　Thread.sleep(1000);
}
```
上面的代码就是一个可重入锁的一个特点。如果不是可重入锁的话，setB可能不会被当前线程执行，可能造成死锁。

### 公平锁/非公平锁

公平锁是指多个线程按照申请锁的顺序来获取锁。

非公平锁是指多个线程获取锁的顺序并不是按照申请锁的顺序，有可能后申请的线程比先申请的线程优先获取锁。有可能，会造成优先级反转或者饥饿现象。

对于Java ReetrantLock而言，通过构造函数指定该锁是否是公平锁，默认是非公平锁。非公平锁的优点在于吞吐量比公平锁大。

对于Synchronized而言，也是一种非公平锁。由于其并不像ReentrantLock是通过AQS的来实现线程调度，所以并没有任何办法使其变成公平锁。

### 分段锁

分段锁其实是一种锁的设计，并不是具体的一种锁，对于ConcurrentHashMap而言，其并发的实现就是通过分段锁的形式来实现高效的并发操作。

我们以ConcurrentHashMap来说一下分段锁的含义以及设计思想，ConcurrentHashMap中的分段锁称为Segment，它即类似于HashMap（JDK7和JDK8中HashMap的实现）的结构，即内部拥有一个Entry数组，数组中的每个元素又是一个链表；同时又是一个ReentrantLock（Segment继承了ReentrantLock）。

当需要put元素的时候，并不是对整个hashmap进行加锁，而是先通过hashcode来知道他要放在哪一个分段中，然后对这个分段进行加锁，所以当多线程put的时候，只要不是放在一个分段中，就实现了真正的并行的插入。

但是，在统计size的时候，可就是获取hashmap全局信息的时候，就需要获取所有的分段锁才能统计。

分段锁的设计目的是细化锁的粒度，当操作不需要更新整个数组的时候，就仅仅针对数组中的一项进行加锁操作。

### 偏向锁/轻量级锁/重量级锁

这三种锁是指锁的状态，并且是针对Synchronized。在Java 5通过引入锁升级的机制来实现高效Synchronized。这三种锁的状态是通过对象监视器在对象头中的字段来表明的。

偏向锁是指一段同步代码一直被一个线程所访问，那么该线程会自动获取锁。降低获取锁的代价。

轻量级锁是指当锁是偏向锁的时候，被另一个线程所访问，偏向锁就会升级为轻量级锁，其他线程会通过自旋的形式尝试获取锁，不会阻塞，提高性能。

重量级锁是指当锁为轻量级锁的时候，另一个线程虽然是自旋，但自旋不会一直持续下去，当自旋一定次数的时候，还没有获取到锁，就会进入阻塞，该锁膨胀为重量级锁。重量级锁会让他申请的线程进入阻塞，性能降低。

### 自旋锁

在Java中，自旋锁是指尝试获取锁的线程不会立即阻塞，而是采用循环的方式去尝试获取锁，这样的好处是减少线程上下文切换的消耗，缺点是循环会消耗CPU。

### 总结

synchronized：可重入锁；非公平锁；独占锁

ReentrantLock：默认非公平锁，构造函数可以设置；可重入锁

ReentrantReadWriteLock：默认非公平锁，构造函数可以设置；可重入锁；遵循获取写锁、获取读锁再释放写锁的次序，写锁能够降级成为读锁

## 锁的使用

### AQS

AbstractQueuedSynchronized 抽象队列式的同步器，AQS定义了一套多线程访问共享资源的同步器框架，许多同步类实现都依赖于它，如常用的ReentrantLock/Semaphore/CountDownLatch…

![在这里插入图片描述](./截图/AQS.png)

AQS维护了一个volatile int state(代表共享资源)和一个FIFO线程等待队列（多线程争用资源被阻塞时会进入此队列）。

state的访问方式有三种：
```
getState()
setState()
compareAndSetState()
```

AQS定义两种资源共享方式：Exclusive（独占，只有一个线程能执行，如ReentrantLock）和Share（共享，多个线程可同时执行，如Semaphore/CountDownLatch）。

不同的自定义同步器争用共享资源的方式也不同。自定义同步器在实现时只需要实现共享资源state的获取与释放方式即可，至于具体线程等待队列的维护（如获取资源失败入队/唤醒出队等），AQS已经在顶层实现好了。自定义同步器实现时主要实现以下几种方法：
```
isHeldExclusively():该线程是否正在独占资源。只有用到condition才需要去实现它。
tryAquire(int):独占方式。尝试获取资源，成功则返回true，失败则返回false。
tryRelease(int):独占方式。尝试释放资源，成功则返回true，失败则返回false。
tryAcquireShared(int):共享方式。尝试获取资源。负数表示失败；0表示成功，但没有剩余可用资源；正数表示成功，且有剩余资源。
tryReleaseShared(int):共享方式。尝试释放资源，如果释放后允许唤醒后续等待结点返回true，否则返回false。
```

以ReentrantLock为例，state初始化为0，表示未锁定状态。A线程lock()时，会调用tryAcquire()独占该锁并将state+1。此后，其他线程再tryAcquire()时就会失败，直到A线程unlock()到state=0（即释放锁）为止，其他线程才有机会获取该锁。当然，释放锁之前，A线程自己是可以重复获取此锁的（state会累加），这就是可重入的概念。但要注意，获取多少次就要释放多少次，这样才能保证state是能回到零态的。

再以CountDownLatch为例，任务分为N个子线程去执行，state为初始化为N（注意N要与线程个数一致）。这N个子线程是并行执行的，每个子线程执行完后countDown()一次，state会CAS减1。等到所有子线程都执行完后（即state=0），会unpark()主调用线程，然后主调用线程就会await()函数返回，继续后余动作。

一般来说，自定义同步器要么是独占方法，要么是共享方式，他们也只需实现tryAcquire-tryRelease、tryAcquireShared-tryReleaseShared中的一种即可。但AQS也支持自定义同步器同时实现独占和共享两种方式，如ReentrantReadWriteLock。

### CAS

CAS（Compare and Swap 比较并交换）是乐观锁技术，当多个线程尝试使用CAS同时更新同一个变量时，只有其中一个线程能更新变量的值，而其他线程都失败，失败的线程并不会被挂起，而是被告知这次竞争中失败，并可以再次尝试。

CAS操作中包含三个操作数——需要读写的内存位置（V）、进行比较的预期原值（A）和拟写入的新值（B）。如果内存位置V的值与预期原值A相匹配，那么处理器会自动将该位置值更新为新值B，否则处理器不做任何操作。无论哪种情况，它都会在CAS指令之前返回该位置的值（在CAS的一些特殊情况下将仅返回CAS是否成功，而不提取当前值）。CAS有效地说明了“我认为位置V应该包含值A；如果包含该值，则将B放到这个位置；否则，不要更改该位置，只告诉我这个位置现在的值即可”。这其实和乐观锁的冲突检查+数据更新的原理是一样的。

JAVA对CAS的支持：

在JDK1.5中新增java.util.concurrent包就是建立在CAS之上的。相对于synchronized这种阻塞算法，CAS是非阻塞算法的一种常见实现。所以java.util.concurrent包中的AtomicInteger为例，看一下在不使用锁的情况下是如何保证线程安全的。主要理解getAndIncrement方法，该方法的作用相当于++i操作。

```
public class AtomicInteger extends Number implements java.io.Serializable{
　　private volatile int value;
　　public final int get(){
　　　　return value;
　　}

　　 public final int getAndIncrement(){
　　　　for (;;){
　　　　　　int current = get();
　　　　　　int next = current + 1;
　　　　　　if (compareAndSet(current, next))
　　　　　　return current;
　　　　}
　　}

　　public final boolean compareAndSet(int expect, int update){
　　　　return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
　　}
}
```