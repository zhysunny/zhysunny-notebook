# Java线程池

## 为什么使用线程池？

服务器应用程序中经常出现的情况是：单个任务处理的时间很短而请求的数目却是巨大的。

为每个请求创建新线程的服务器在创建和销毁线程上花费的时间和消耗的系统资源要比花在处理实际的用户请求的时间和资源更多

除了创建和销毁线程的开销之外，活动的线程也消耗系统资源。在一个 JVM 里创建太多的线程可能会导致系统由于过度消耗内存而用完内存或“切换过度”。为了防止资源不足，服务器应用程序需要一些办法来限制任何给定时刻处理的请求数目。

总结：线程池为**线程生命周期开销问题**和**资源不足问题**提供了解决方案

## 线程池的替代方案

线程池远不是服务器应用程序内使用多线程的唯一方法。如同上面所提到的，有时，为每个新任务生成一个新线程是十分明智的。然而，如果任务创建过于频繁而任务的平均处理时间过短，那么为每个任务生成一个新线程将会导致性能问题。

另一个常见的线程模型是为某一类型的任务分配一个后台线程与任务队列。AWT 和 Swing 就使用这个模型，在这个模型中有一个 GUI 事件线程，导致用户界面发生变化的所有工作都必须在该线程中执行。然而，由于只有一个 AWT 线程，因此要在 AWT 线程中执行任务可能要花费相当长时间才能完成，这是不可取的。因此，Swing 应用程序经常需要额外的工作线程，用于运行时间很长的、同 UI 有关的任务。

每个任务对应一个线程方法和单个后台线程（single-background-thread）方法在某些情形下都工作得非常理想。每个任务一个线程方法在只有少量运行时间很长的任务时工作得十分好。而只要调度可预见性不是很重要，则单个后台线程方法就工作得十分好，如低优先级后台任务就是这种情况。然而，大多数服务器应用程序都是面向处理大量的短期任务或子任务，因此往往希望具有一种能够以低开销有效地处理这些任务的机制以及一些资源管理和定时可预见性的措施。线程池提供了这些优点。

## 使用线程池的风险

虽然线程池是构建多线程应用程序的强大机制，但使用它并不是没有风险的。用线程池构建的应用程序容易遭受任何其它多线程应用程序容易遭受的所有并发风险，诸如同步错误和死锁，它还容易遭受特定于线程池的少数其它风险，诸如与池有关的死锁、资源不足和线程泄漏。

### 死锁

任何多线程应用程序都有死锁风险。当一组进程或线程中的每一个都在等待一个只有该组中另一个进程才能引起的事件时，我们就说这组进程或线程 死锁了。

死锁的最简单情形是：线程 A 持有对象 X 的独占锁，并且在等待对象 Y 的锁，而线程 B 持有对象 Y 的独占锁，却在等待对象 X 的锁。除非有某种方法来打破对锁的等待（Java 锁定不支持这种方法），否则死锁的线程将永远等下去。

虽然任何多线程程序中都有死锁的风险，但线程池却引入了另一种死锁可能，在那种情况下，所有池线程都在执行已阻塞的等待队列中另一任务的执行结果的任务，但这一任务却因为没有未被占用的线程而不能运行。当线程池被用来实现涉及许多交互对象的模拟，被模拟的对象可以相互发送查询，这些查询接下来作为排队的任务执行，查询对象又同步等待着响应时，会发生这种情况。

### 资源不足

线程池的一个优点在于：相对于其它替代调度机制（有些我们已经讨论过）而言，它们通常执行得很好。但只有恰当地调整了线程池大小时才是这样的。线程消耗包括内存和其它系统资源在内的大量资源。除了 Thread 对象所需的内存之外，每个线程都需要两个可能很大的执行调用堆栈。除此以外，JVM 可能会为每个 Java 线程创建一个本机线程，这些本机线程将消耗额外的系统资源。最后，虽然线程之间切换的调度开销很小，但如果有很多线程，环境切换也可能严重地影响程序的性能。

如果线程池太大，那么被那些线程消耗的资源可能严重地影响系统性能。在线程之间进行切换将会浪费时间，而且使用超出比您实际需要的线程可能会引起资源匮乏问题，因为池线程正在消耗一些资源，而这些资源可能会被其它任务更有效地利用。除了线程自身所使用的资源以外，服务请求时所做的工作可能需要其它资源，例如 JDBC 连接、套接字或文件。这些也都是有限资源，有太多的并发请求也可能引起失效，例如不能分配 JDBC 连接。

### 并发错误

线程池和其它排队机制依靠使用 wait() 和 notify() 方法，这两个方法都难于使用。如果编码不正确，那么可能丢失通知，导致线程保持空闲状态，尽管队列中有工作要处理。使用这些方法时，必须格外小心；即便是专家也可能在它们上面出错。而最好使用现有的、已经知道能工作的实现，例如在下面的 无须编写您自己的池中讨论的 util.concurrent 包。

### 线程泄漏

各种类型的线程池中一个严重的风险是线程泄漏，当从池中除去一个线程以执行一项任务，而在任务完成后该线程却没有返回池时，会发生这种情况。发生线程泄漏的一种情形出现在任务抛出一个 RuntimeException 或一个 Error 时。如果池类没有捕捉到它们，那么线程只会退出而线程池的大小将会永久减少一个。当这种情况发生的次数足够多时，线程池最终就为空，而且系统将停止，因为没有可用的线程来处理任务。

有些任务可能会永远等待某些资源或来自用户的输入，而这些资源又不能保证变得可用，用户可能也已经回家了，诸如此类的任务会永久停止，而这些停止的任务也会引起和线程泄漏同样的问题。如果某个线程被这样一个任务永久地消耗着，那么它实际上就被从池除去了。对于这样的任务，应该要么只给予它们自己的线程，要么只让它们等待有限的时间。

### 请求过载

仅仅是请求就压垮了服务器，这种情况是可能的。在这种情形下，我们可能不想将每个到来的请求都排队到我们的工作队列，因为排在队列中等待执行的任务可能会消耗太多的系统资源并引起资源缺乏。在这种情形下决定如何做取决于您自己；在某些情况下，您可以简单地抛弃请求，依靠更高级别的协议稍后重试请求，您也可以用一个指出服务器暂时很忙的响应来拒绝请求。

## 有效使用线程池的准则

* 不要对那些同步等待其它任务结果的任务排队(死锁)
* 在为时间可能很长的操作使用合用的线程时要小心
* 调整池的大小

线程池的最佳大小取决于可用处理器的数目以及工作队列中的任务的性质。若在一个具有 N 个处理器的系统上只有一个工作队列，其中全部是计算性质的任务，在线程池具有 N 或 N+1 个线程时一般会获得最大的 CPU 利用率。

对于那些可能需要等待 I/O 完成的任务（例如，从套接字读取 HTTP 请求的任务），需要让池的大小超过可用处理器的数目，因为并不是所有线程都一直在工作。通过使用概要分析，您可以估计某个典型请求的等待时间（WT）与服务时间（ST）之间的比例。如果我们将这一比例称之为 WT/ST，那么对于一个具有 N 个处理器的系统，需要设置大约 N*(1+WT/ST) 个线程来保持处理器得到充分利用。

处理器利用率不是调整线程池大小过程中的唯一考虑事项。随着线程池的增长，您可能会碰到调度程序、可用内存方面的限制，或者其它系统资源方面的限制，例如套接字、打开的文件句柄或数据库连接等的数目

## 常见的线程池及使用场景

java里面的线程池的顶级接口是Executor，Executor并不是一个线程池，而只是一个执行线程的工具，而真正的线程池是ExecutorService。

### newCachedThreadPool

newCachedThreadPool,是一种线程数量不定的线程池，并且其最大线程数为Integer.MAX_VALUE，这个数是很大的，一个可缓存线程池，如果线程池长度超过处理需要，可灵活回收空闲线程，若无可回收，则新建线程。但是线程池中的空闲线程都有超时限制，这个超时时长是60秒，超过60秒闲置线程就会被回收。调用execute将重用以前构造的线程(如果线程可用)。这类线程池比较适合执行大量的耗时较少的任务，当整个线程池都处于闲置状态时，线程池中的线程都会超时被停止。

### newFixedThreadPool

创建一个指定工作线程数量的线程池，每当提交一个任务就创建一个工作线程，当线程 处于空闲状态时，它们并不会被回收，除非线程池被关闭了，如果工作线程数量达到线程池初始的最大数，则将提交的任务存入到池队列（没有大小限制）中。由于newFixedThreadPool只有核心线程并且这些核心线程不会被回收，这样它更加快速的响应外界的请求。

### newScheduledThreadPool

创建一个线程池，它的核心线程数量是固定的，而非核心线程数是没有限制的，并且当非核心线程闲置时会被立即回收，它可安排给定延迟后运行命令或者定期地执行。这类线程池主要用于执行定时任务和具有固定周期的重复任务。

### newSingleThreadExecutor

这类线程池内部只有一个核心线程，以无界队列方式来执行该线程，这使得这些任务之间不需要处理线程同步的问题，它确保所有的任务都在同一个线程中按顺序中执行，并且可以在任意给定的时间不会有多个线程是活动的。


## 线程池工作队列

### ArrayBlockingQueue 数组型阻塞队列

初始化一定容量的数组
使用一个重入锁，默认使用非公平锁，入队和出队共用一个锁，互斥
是有界设计，如果容量满无法继续添加元素直至有元素被移除
使用时开辟一段连续的内存，如果初始化容量过大容易造成资源浪费，过小易添加失败

### LinkedBlockingQueue 链表型阻塞队列

内部使用节点关联，会产生多一点内存占用 
使用两个重入锁分别控制元素的入队和出队，用Condition进行线程间的唤醒和等待
有边界的，在默认构造方法中容量是Integer.MAX_VALUE
非连续性内存空间

### DelayQueue 延时队列

无边界设计
添加（put）不阻塞，移除阻塞
元素都有一个过期时间
取元素只有过期的才会被取出

### SynchronousQueue 同步队列

内部容量是0
每次删除操作都要等待插入操作
每次插入操作都要等待删除操作
一个元素，一旦有了插入线程和移除线程，那么很快由插入线程移交给移除线程，这个容器相当于通道，本身不存储元素
在多任务队列，是最快的处理任务方式。

### PriorityBlockingQueue 优先阻塞队列

无边界设计，但容量实际是依靠系统资源影响
添加元素，如果超过1，则进入优先级排序

## 线程池中的几种重要的参数及流程说明

### 参数

corePoolSize ：核心线程数量

maximumPoolSize ：线程最大线程数

workQueue ：阻塞队列，存储等待执行的任务 很重要 会对线程池运行产生重大影响

keepAliveTime ：线程没有任务时最多保持多久时间终止

unit ：keepAliveTime的时间单位

threadFactory ：线程工厂，用来创建线程

rejectHandler ：当拒绝处理任务时的策略

### 方法

execute（）：提交任务，交给线程池执行

submit（）：提交任务，能够返回执行结果 execute + Future

shutdown（）：关闭线程池，等待任务都执行完

shutdownNow（）：关闭线程池，不等待任务执行完

getTaskCount（）：线程池已执行和未执行的任务总数

getCompletedTaskCount（）：已完成的任务数量

getPoolSize（）：线程池当前的线程数量

getActiveCount（）：当前线程池中正在执行任务的线程数量

### 线程池 - Executor框架接口

Executors.newCachedThreadPool : 可缓存线程池，超过需要会回收多余线程，线程不足会创建新线程

Executors.newFixedThreadPool ：定长线程池，超出线程等待

Executors.newScheduledThreadPool ：定长线程池，支持定时，周期性任务执行

Executors.newSingleThreadExecutor ：单线程线程池，按照指定任务顺序执行

### 线程池 - 合理配置

cpu密集型任务，就需要尽量压榨CPU，参考值设为NCPU+1

IO密集型任务，参考值设为2*NCPU

### 线程池特点

线程池的使用主要是同用存在线程，减少对象创建消亡，有效线程最大并发数，避免过多资源竞争，避免阻塞，性能较好